import { supabase, Message, Conversation } from './supabase';
import { analyzeImageForCropDisease, getChatResponse, ChatMessage } from './openrouter';

export type ConversationState =
  | 'awaiting_image'
  | 'processing_image'
  | 'collecting_soil_type'
  | 'collecting_water_level'
  | 'collecting_nitrogen'
  | 'collecting_phosphorous'
  | 'collecting_potassium'
  | 'generating_recommendations'
  | 'awaiting_acreage'
  | 'presenting_fertilizers'
  | 'awaiting_rating'
  | 'completed';

const SUPPORTED_CROPS = [
  'Sugarcane',
  'Turmeric',
  'Groundnut',
  'Blackgram',
  'Sunflower',
  'Wheat',
  'Paddy',
  'Rice',
  'Eggplant',
  'Brinjal',
  'Cotton',
  'Tomato',
];

const SOIL_TYPE_OPTIONS = [
  'Clay',
  'Sandy',
  'Loamy',
  'Red soil',
  'Black soil',
  'Alluvial soil',
  'Laterite soil',
  'Desert soil',
];

const WATER_LEVEL_OPTIONS = [
  'Drip irrigation',
  'Flood irrigation',
  'Rainfed',
  'Sprinkler irrigation',
  'Drip and sprinkler',
  'Manual/hand watering',
  'Canal irrigation',
  'Well irrigation',
];

// Convert climate string to numerical value
function getClimateNumericalValue(climate: string): number {
  switch (climate.toLowerCase()) {
    case 'tropical':
      return 1;
    case 'subtropical':
      return 2;
    case 'temperate':
      return 3;
    case 'polar/cold':
      return 4;
    default:
      return 3; // Default to Temperate (3)
  }
}

export class ConversationManager {
  private sessionId: string;
  private conversation: Conversation | null = null;
  private useLocalFallback = false;
  private localKey: string;
  private autoDetectedClimate: string | null = null;
  private userLatitude: number | null = null;
  private userLongitude: number | null = null;

  constructor(sessionId: string) {
    this.sessionId = sessionId;
    this.localKey = `local_conversation_${this.sessionId}`;
  }

  setAutoDetectedClimate(climate: string): void {
    this.autoDetectedClimate = climate;
  }

  setUserLocation(latitude: number, longitude: number): void {
    this.userLatitude = latitude;
    this.userLongitude = longitude;
  }

  private async fetchSoilTemperatureFromCloud(): Promise<string> {
    // Fetch weather data using OpenWeather API
    // If coordinates not available, use default
    const lat = this.userLatitude || 20.5937; // Default to India
    const lon = this.userLongitude || 78.9629;

    try {
      // Using open-meteo API (free, no API key required)
      const response = await fetch(
        `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=soil_temperature_0cm,soil_moisture_0_to_1cm&timezone=auto`
      );

      if (response.ok) {
        const data = await response.json();
        const soilTemp = data.current?.soil_temperature_0cm;
        if (soilTemp !== undefined && soilTemp !== null) {
          return soilTemp.toString();
        }
      }
    } catch (error) {
      console.warn('Error fetching soil temperature from cloud:', error);
    }

    // Return default/placeholder if API fails
    return 'auto_detected';
  }

  async initialize(): Promise<void> {
    // Try fetching from Supabase; if network fails, fall back to localStorage
    try {
      const { data, error } = await supabase
        .from('conversations')
        .select('*')
        .eq('session_id', this.sessionId)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (error && (error as any).code !== 'PGRST116') {
        console.error('Error fetching conversation:', (error as any)?.message ?? error, error);
        throw error;
      }

      if (data) {
        this.conversation = data as Conversation;
        return;
      }
    } catch (err) {
      console.warn('Network error fetching conversation from Supabase, enabling local fallback:', err);
      this.useLocalFallback = true;
    }

    // If Supabase didn't return a conversation or network failed, try localStorage
    if (this.useLocalFallback) {
      const stored = typeof window !== 'undefined' ? window.localStorage.getItem(this.localKey) : null;
      if (stored) {
        try {
          this.conversation = JSON.parse(stored) as Conversation;
          return;
        } catch (e) {
          console.warn('Failed to parse local conversation, creating new one.', e);
        }
      }

      // create local conversation
      this.conversation = {
        id: `local-${Date.now()}`,
        session_id: this.sessionId,
        messages: [],
        current_state: 'awaiting_image',
        crop_data: {},
        soil_data: {},
        acreage: 0,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      } as Conversation;

      this.saveLocalConversation();
      return;
    }

    // If no conversation exists remotely, create one on Supabase
    try {
      const { data: newConv, error: createError } = await supabase
        .from('conversations')
        .insert({
          session_id: this.sessionId,
          messages: [],
          current_state: 'awaiting_image',
          crop_data: {},
          soil_data: {},
          acreage: 0,
        })
        .select()
        .single();

      if (createError) {
        console.error('Error creating conversation:', createError);
        throw createError;
      }

      this.conversation = newConv as Conversation;
    } catch (err) {
      console.error('Network error creating conversation in Supabase:', err);
      // if creation fails, enable local fallback and create locally
      this.useLocalFallback = true;
      this.conversation = {
        id: `local-${Date.now()}`,
        session_id: this.sessionId,
        messages: [],
        current_state: 'awaiting_image',
        crop_data: {},
        soil_data: {},
        acreage: 0,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      } as Conversation;
      this.saveLocalConversation();
    }
  }

  private saveLocalConversation() {
    try {
      if (typeof window !== 'undefined') {
        window.localStorage.setItem(this.localKey, JSON.stringify(this.conversation));
      }
    } catch (e) {
      console.warn('Failed to save local conversation:', e);
    }
  }

  async addMessage(
    role: 'user' | 'assistant',
    content: string,
    imageUrl?: string,
    dropdown?: { type: 'soil_type' | 'water_level'; options: string[] }
  ): Promise<void> {
    if (!this.conversation) await this.initialize();

    const message: Message = {
      role,
      content,
      imageUrl,
      timestamp: Date.now(),
      dropdown,
    };

    const updatedMessages = [...(this.conversation!.messages || []), message];

    if (this.useLocalFallback) {
      this.conversation!.messages = updatedMessages;
      this.conversation!.updated_at = new Date().toISOString();
      this.saveLocalConversation();
      return;
    }

    try {
      const { error } = await supabase
        .from('conversations')
        .update({
          messages: updatedMessages,
          updated_at: new Date().toISOString(),
        })
        .eq('id', this.conversation!.id);

      if (error) {
        console.error('Error updating messages:', error);
        // switch to local fallback so the UI remains usable
        this.useLocalFallback = true;
        this.conversation!.messages = updatedMessages;
        this.saveLocalConversation();
        return;
      }

      this.conversation!.messages = updatedMessages;
    } catch (err) {
      console.warn('Network error updating messages, switching to local fallback:', err);
      this.useLocalFallback = true;
      this.conversation!.messages = updatedMessages;
      this.saveLocalConversation();
    }
  }

  async processImageUpload(imageDataUrl: string): Promise<string> {
    if (!this.conversation) await this.initialize();

    await this.addMessage('user', 'Uploaded crop image', imageDataUrl);
    await this.updateState('processing_image');

    try {
      const conversationHistory: ChatMessage[] = this.conversation!.messages.map((msg) => ({
        role: msg.role,
        content: msg.content,
      }));

      const analysisResult = await analyzeImageForCropDisease(imageDataUrl, conversationHistory);

      const detectedCrop = this.extractCropName(analysisResult);
      const detectedDisease = this.extractDiseaseName(analysisResult);

      // Check if the response indicates an unsupported crop
      if (analysisResult.toLowerCase().includes('unsupported crop') || 
          analysisResult.toLowerCase().includes('not supported') ||
          analysisResult.toLowerCase().includes('not in the supported')) {
        await this.updateState('awaiting_image');
        const response = 'This is an unsupported crop. Please upload an image of one of these supported crops: Sugarcane, Turmeric, Groundnut, Blackgram, Sunflower, Wheat, Paddy (Rice), Eggplant (Brinjal), Cotton, or Tomato.';
        await this.addMessage('assistant', response);
        return response;
      } else if (detectedCrop && this.isSupportedCrop(detectedCrop)) {
        await this.updateCropData(detectedCrop, detectedDisease || 'Unknown');
        await this.updateState('collecting_soil_type');

        const response = `${analysisResult}\n\nGreat! Now, please tell me about your soil and climate conditions so I can recommend the best fertilizers.\n\nFirst, what is your Soil Type?`;

        await this.addMessage('assistant', response, undefined, {
          type: 'soil_type',
          options: SOIL_TYPE_OPTIONS,
        });
        return response;
      } else if (analysisResult.toLowerCase().includes('please upload') ||
                 analysisResult.toLowerCase().includes('unclear') ||
                 analysisResult.toLowerCase().includes('better image')) {
        await this.updateState('awaiting_image');
        await this.addMessage('assistant', analysisResult);
        return analysisResult;
      } else {
        await this.updateState('awaiting_image');
        const response = `${analysisResult}\n\nPlease upload an image of one of these supported crops: Sugarcane, Turmeric, Groundnut, Blackgram, Sunflower, Wheat, Paddy (Rice), Eggplant (Brinjal), Cotton, or Tomato.`;
        await this.addMessage('assistant', response);
        return response;
      }
    } catch (error) {
      console.error('Error processing image:', error);
      await this.updateState('awaiting_image');
      const errorResponse =
        'I encountered an error while analyzing the image. Please try uploading a clear photo of your crop taken in good lighting.';
      await this.addMessage('assistant', errorResponse);
      return errorResponse;
    }
  }

  async processTextInput(userInput: string): Promise<string> {
    if (!this.conversation) await this.initialize();

    await this.addMessage('user', userInput);

    const state = this.conversation!.current_state as ConversationState;

    switch (state) {
      case 'collecting_soil_type':
        return await this.handleSoilType(userInput);
      case 'collecting_water_level':
        return await this.handleWaterLevel(userInput);
      case 'collecting_nitrogen':
        return await this.handleNitrogen(userInput);
      case 'collecting_phosphorous':
        return await this.handlePhosphorous(userInput);
      case 'collecting_potassium':
        return await this.handlePotassium(userInput);
      case 'awaiting_acreage':
        return await this.handleAcreage(userInput);
      case 'awaiting_rating':
        return await this.handleRating(userInput);
      case 'awaiting_image':
        const response = 'Please upload an image of your crop so I can analyze it for diseases.';
        await this.addMessage('assistant', response);
        return response;
      default:
        const defaultResponse = 'Please upload an image of your crop to get started.';
        await this.addMessage('assistant', defaultResponse);
        return defaultResponse;
    }
  }

  private async handleSoilType(input: string): Promise<string> {
    await this.updateSoilData({ soilType: input });
    
    // Auto-set the climate condition as numerical value
    const climate = this.autoDetectedClimate || 'Temperate';
    const climateNumerical = getClimateNumericalValue(climate);
    await this.updateSoilData({ climate: climateNumerical.toString() });
    
    // Skip climate question and go directly to water level
    await this.updateState('collecting_water_level');
    const response = `Thank you! I've detected your climate as **${climate}** (Code: ${climateNumerical}) based on your location.\n\nNow, what is your Water Level or Irrigation Method?`;
    await this.addMessage('assistant', response, undefined, {
      type: 'water_level',
      options: WATER_LEVEL_OPTIONS,
    });
    return response;
  }

  private async handleWaterLevel(input: string): Promise<string> {
    await this.updateSoilData({ waterLevel: input });
    
    // Auto-fetch soil temperature from cloud service
    const soilTemp = await this.fetchSoilTemperatureFromCloud();
    await this.updateSoilData({ soilTemp });
    
    await this.updateState('collecting_nitrogen');
    const response = `Thank you! I've detected your soil temperature from cloud services.\n\nWhat is the Amount of Nitrogen (N) in your soil?`;
    await this.addMessage('assistant', response);
    return response;
  }

  private async handleNitrogen(input: string): Promise<string> {
    await this.updateSoilData({ nitrogen: input });
    await this.updateState('collecting_phosphorous');
    const response = 'What is the Amount of Phosphorous (P) in your soil?';
    await this.addMessage('assistant', response);
    return response;
  }

  private async handlePhosphorous(input: string): Promise<string> {
    await this.updateSoilData({ phosphorous: input });
    await this.updateState('collecting_potassium');
    const response = 'What is the Amount of Potassium (K) in your soil?';
    await this.addMessage('assistant', response);
    return response;
  }

  private async handlePotassium(input: string): Promise<string> {
    await this.updateSoilData({ potassium: input });
    await this.updateState('generating_recommendations');

    const response = 'Thank you for providing all the information! Let me generate personalized fertilizer recommendations for your crop...';
    await this.addMessage('assistant', response);

    const recommendations = await this.generateFertilizerRecommendations();
    await this.updateState('awaiting_acreage');

    await this.addMessage('assistant', recommendations);
    return recommendations;
  }

  private async handleAcreage(input: string): Promise<string> {
    const acreage = parseFloat(input);

    if (isNaN(acreage) || acreage <= 0) {
      const response = 'Please provide a valid number of acres (for example: 2.5 or 5).';
      await this.addMessage('assistant', response);
      return response;
    }

    await this.updateAcreage(acreage);

    const calculations = this.calculateQuantities(acreage);
    await this.updateState('awaiting_rating');

    const response = `${calculations}\n\nHow would you rate this fertilizer recommendation? Please rate from 1 to 5 stars (1 = Poor, 5 = Excellent).`;
    await this.addMessage('assistant', response);

    // Send thank you message with animation and icon after calculations
    const thankYouMessage = `Thank You! 🙏`;
    const iconUrl = 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQFjJlAkaIpnXBm80ou4P_niKFxmqglq2fCRA&s';
    await this.addMessage('assistant', `<span style="display: inline-block; animation: slideInLeftToRight 1s ease-in-out; text-align: center; width: 100%;">
<img src="${iconUrl}" alt="Thank You" style="width: 60px; height: 60px; margin: 10px auto; display: block; border-radius: 50%; object-fit: cover;" />
<strong>${thankYouMessage}</strong>
</span>`);
    return response;
  }

  private async handleRating(input: string): Promise<string> {
    const rating = parseInt(input);

    if (isNaN(rating) || rating < 1 || rating > 5) {
      const response = 'Please provide a rating between 1 and 5.';
      await this.addMessage('assistant', response);
      return response;
    }

    await this.saveRating(rating);
    await this.scheduleReminders();
    await this.updateState('completed');

    const avgRating = await this.getAverageRating();

    const response = `Thank you for your rating of ${rating} stars! The average rating for this fertilizer is ${avgRating.toFixed(1)} stars.\n\nI've set up reminders for you:\n- In 24 hours: Apply the fertilizer\n- In 3 days: Upload a new image to check your crop's health\n\nI'll help you monitor your crop's progress and adjust recommendations as needed. Good luck with your farming!`;
    await this.addMessage('assistant', response);
    return response;
  }

  private async generateFertilizerRecommendations(): Promise<string> {
    const cropData = this.conversation!.crop_data;
    const soilData = this.conversation!.soil_data;

    const systemPrompt = `You are an expert agricultural advisor. Generate detailed fertilizer recommendations for the farmer.

CROP: ${cropData.crop}
DISEASE: ${cropData.disease}
SOIL TYPE: ${soilData.soilType}
CLIMATE: ${soilData.climate}
WATER LEVEL: ${soilData.waterLevel}
SOIL TEMPERATURE: ${soilData.soilTemp || 'Not provided'}
NITROGEN: ${soilData.nitrogen || 'Not provided'}
PHOSPHOROUS: ${soilData.phosphorous || 'Not provided'}
POTASSIUM: ${soilData.potassium || 'Not provided'}

Generate fertilizer recommendations in THREE categories:
1. Medical/Chemical Fertilizers
2. Natural/Organic Fertilizers
3. Bio-fertilizers

For EACH fertilizer, provide:
- Name
- Composition
- Dosage per acre
- Application method
- Timing
- Precautions
- Advantages
- Disadvantages
- Suitability for this disease and climate

Format your response clearly with headers and bullet points. Be specific and practical. Use simple farmer-friendly language.

After listing all fertilizers, ask: "How many acres is your crop cultivated on?"`;

    const conversationHistory: ChatMessage[] = [
      { role: 'system', content: systemPrompt },
    ];

    return await getChatResponse(conversationHistory, systemPrompt);
  }

  private calculateQuantities(acreage: number): string {
    const baseWaterPerAcre = 1000;
    const waterAmount = acreage * baseWaterPerAcre;

    return `Based on ${acreage} acres of cultivation:\n\n- Multiply the recommended fertilizer dosage per acre by ${acreage}\n- Recommended water amount: Approximately ${waterAmount.toLocaleString()} liters\n- Apply fertilizer evenly across the field\n- Ensure proper irrigation after application`;
  }

  private async saveRating(rating: number): Promise<void> {
    const cropData = this.conversation!.crop_data;
    const ratingObj = {
      fertilizer_name: 'Recommended Fertilizer',
      crop_type: cropData.crop || 'Unknown',
      disease_type: cropData.disease || 'Unknown',
      rating,
      session_id: this.sessionId,
      created_at: new Date().toISOString(),
    };

    if (this.useLocalFallback) {
      try {
        const key = `local_ratings_${this.sessionId}`;
        const stored = typeof window !== 'undefined' ? window.localStorage.getItem(key) : null;
        const arr = stored ? JSON.parse(stored) : [];
        arr.push(ratingObj);
        if (typeof window !== 'undefined') window.localStorage.setItem(key, JSON.stringify(arr));
      } catch (e) {
        console.warn('Failed to save local rating:', e);
      }
      return;
    }

    try {
      const { error } = await supabase.from('fertilizer_ratings').insert(ratingObj);
      if (error) {
        console.error('Error saving rating to Supabase:', error);
        this.useLocalFallback = true;
        // fall back to local
        const key = `local_ratings_${this.sessionId}`;
        const stored = typeof window !== 'undefined' ? window.localStorage.getItem(key) : null;
        const arr = stored ? JSON.parse(stored) : [];
        arr.push(ratingObj);
        if (typeof window !== 'undefined') window.localStorage.setItem(key, JSON.stringify(arr));
      }
    } catch (err) {
      console.warn('Network error saving rating, switching to local fallback:', err);
      this.useLocalFallback = true;
      const key = `local_ratings_${this.sessionId}`;
      const stored = typeof window !== 'undefined' ? window.localStorage.getItem(key) : null;
      const arr = stored ? JSON.parse(stored) : [];
      arr.push(ratingObj);
      if (typeof window !== 'undefined') window.localStorage.setItem(key, JSON.stringify(arr));
    }
  }

  private async getAverageRating(): Promise<number> {
    const cropData = this.conversation!.crop_data;
    if (this.useLocalFallback) {
      try {
        const key = `local_ratings_${this.sessionId}`;
        const stored = typeof window !== 'undefined' ? window.localStorage.getItem(key) : null;
        const arr = stored ? JSON.parse(stored) : [];
        const filtered = arr.filter((r: any) => (r.crop_type || 'Unknown') === (cropData.crop || 'Unknown') && (r.disease_type || 'Unknown') === (cropData.disease || 'Unknown'));
        if (!filtered || filtered.length === 0) return 0;
        const sum = filtered.reduce((acc: number, item: any) => acc + item.rating, 0);
        return sum / filtered.length;
      } catch (e) {
        console.warn('Failed to compute local average rating:', e);
        return 0;
      }
    }

    try {
      const { data, error } = await supabase
        .from('fertilizer_ratings')
        .select('rating')
        .eq('crop_type', cropData.crop || 'Unknown')
        .eq('disease_type', cropData.disease || 'Unknown');

      if (error || !data || data.length === 0) return 0;
      const sum = data.reduce((acc, item) => acc + item.rating, 0);
      return sum / data.length;
    } catch (err) {
      console.warn('Network error fetching ratings, switching to local fallback:', err);
      this.useLocalFallback = true;
      const key = `local_ratings_${this.sessionId}`;
      const stored = typeof window !== 'undefined' ? window.localStorage.getItem(key) : null;
      const arr = stored ? JSON.parse(stored) : [];
      const filtered = arr.filter((r: any) => (r.crop_type || 'Unknown') === (cropData.crop || 'Unknown') && (r.disease_type || 'Unknown') === (cropData.disease || 'Unknown'));
      if (!filtered || filtered.length === 0) return 0;
      const sum = filtered.reduce((acc: number, item: any) => acc + item.rating, 0);
      return sum / filtered.length;
    }
  }

  private async scheduleReminders(): Promise<void> {
    const now = new Date();
    const applyFertilizerTime = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const followUpImageTime = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);
    const reminders = [
      {
        session_id: this.sessionId,
        reminder_type: 'apply_fertilizer',
        scheduled_at: applyFertilizerTime.toISOString(),
        completed: false,
      },
      {
        session_id: this.sessionId,
        reminder_type: 'upload_followup',
        scheduled_at: followUpImageTime.toISOString(),
        completed: false,
      },
    ];

    if (this.useLocalFallback) {
      try {
        const key = `local_reminders_${this.sessionId}`;
        const stored = typeof window !== 'undefined' ? window.localStorage.getItem(key) : null;
        const arr = stored ? JSON.parse(stored) : [];
        arr.push(...reminders);
        if (typeof window !== 'undefined') window.localStorage.setItem(key, JSON.stringify(arr));
      } catch (e) {
        console.warn('Failed to save local reminders:', e);
      }
      return;
    }

    try {
      const { error } = await supabase.from('reminders').insert(reminders);
      if (error) {
        console.error('Error creating reminders in Supabase:', error);
        this.useLocalFallback = true;
        const key = `local_reminders_${this.sessionId}`;
        const stored = typeof window !== 'undefined' ? window.localStorage.getItem(key) : null;
        const arr = stored ? JSON.parse(stored) : [];
        arr.push(...reminders);
        if (typeof window !== 'undefined') window.localStorage.setItem(key, JSON.stringify(arr));
      }
    } catch (err) {
      console.warn('Network error creating reminders, switching to local fallback:', err);
      this.useLocalFallback = true;
      const key = `local_reminders_${this.sessionId}`;
      const stored = typeof window !== 'undefined' ? window.localStorage.getItem(key) : null;
      const arr = stored ? JSON.parse(stored) : [];
      arr.push(...reminders);
      if (typeof window !== 'undefined') window.localStorage.setItem(key, JSON.stringify(arr));
    }
  }

  private extractCropName(text: string): string | null {
    const lowerText = text.toLowerCase();
    for (const crop of SUPPORTED_CROPS) {
      if (lowerText.includes(crop.toLowerCase())) {
        return crop;
      }
    }
    return null;
  }

  private extractDiseaseName(text: string): string | null {
    const diseaseKeywords = ['blight', 'rot', 'wilt', 'rust', 'spot', 'disease', 'infection', 'fungus', 'pest', 'healthy', 'mosaic','leaf curl','yellow','virus'];
    const lowerText = text.toLowerCase();

    for (const keyword of diseaseKeywords) {
      if (lowerText.includes(keyword)) {
        const sentences = text.split(/[.!?]/);
        for (const sentence of sentences) {
          if (sentence.toLowerCase().includes(keyword)) {
            return sentence.trim();
          }
        }
      }
    }
    return null;
  }

  private isSupportedCrop(crop: string): boolean {
    return SUPPORTED_CROPS.some((supported) => supported.toLowerCase() === crop.toLowerCase());
  }

  async updateState(state: ConversationState): Promise<void> {
    if (!this.conversation) return;
    this.conversation.current_state = state;

    if (this.useLocalFallback) {
      this.conversation.updated_at = new Date().toISOString();
      this.saveLocalConversation();
      return;
    }

    try {
      const { error } = await supabase
        .from('conversations')
        .update({ current_state: state, updated_at: new Date().toISOString() })
        .eq('id', this.conversation.id);

      if (error) {
        console.error('Error updating state in Supabase:', error);
        this.useLocalFallback = true;
        this.conversation.updated_at = new Date().toISOString();
        this.saveLocalConversation();
      }
    } catch (err) {
      console.warn('Network error updating state, switching to local fallback:', err);
      this.useLocalFallback = true;
      this.conversation.updated_at = new Date().toISOString();
      this.saveLocalConversation();
    }
  }

  async updateCropData(crop: string, disease: string): Promise<void> {
    if (!this.conversation) return;

    const cropData = { crop, disease };
    this.conversation.crop_data = cropData;

    if (this.useLocalFallback) {
      this.conversation.updated_at = new Date().toISOString();
      this.saveLocalConversation();
      return;
    }

    try {
      const { error } = await supabase
        .from('conversations')
        .update({ crop_data: cropData, updated_at: new Date().toISOString() })
        .eq('id', this.conversation.id);

      if (error) {
        console.error('Error updating crop data in Supabase:', error);
        this.useLocalFallback = true;
        this.conversation.updated_at = new Date().toISOString();
        this.saveLocalConversation();
      }
    } catch (err) {
      console.warn('Network error updating crop data, switching to local fallback:', err);
      this.useLocalFallback = true;
      this.conversation.updated_at = new Date().toISOString();
      this.saveLocalConversation();
    }
  }

  async updateSoilData(data: Partial<Conversation['soil_data']>): Promise<void> {
    if (!this.conversation) return;

    const soilData = { ...this.conversation.soil_data, ...data };
    this.conversation.soil_data = soilData;

    if (this.useLocalFallback) {
      this.conversation.updated_at = new Date().toISOString();
      this.saveLocalConversation();
      return;
    }

    try {
      const { error } = await supabase
        .from('conversations')
        .update({ soil_data: soilData, updated_at: new Date().toISOString() })
        .eq('id', this.conversation.id);

      if (error) {
        console.error('Error updating soil data in Supabase:', error);
        this.useLocalFallback = true;
        this.conversation.updated_at = new Date().toISOString();
        this.saveLocalConversation();
      }
    } catch (err) {
      console.warn('Network error updating soil data, switching to local fallback:', err);
      this.useLocalFallback = true;
      this.conversation.updated_at = new Date().toISOString();
      this.saveLocalConversation();
    }
  }

  async updateAcreage(acreage: number): Promise<void> {
    if (!this.conversation) return;
    this.conversation.acreage = acreage;

    if (this.useLocalFallback) {
      this.conversation.updated_at = new Date().toISOString();
      this.saveLocalConversation();
      return;
    }

    try {
      const { error } = await supabase
        .from('conversations')
        .update({ acreage, updated_at: new Date().toISOString() })
        .eq('id', this.conversation.id);

      if (error) {
        console.error('Error updating acreage in Supabase:', error);
        this.useLocalFallback = true;
        this.conversation.updated_at = new Date().toISOString();
        this.saveLocalConversation();
      }
    } catch (err) {
      console.warn('Network error updating acreage, switching to local fallback:', err);
      this.useLocalFallback = true;
      this.conversation.updated_at = new Date().toISOString();
      this.saveLocalConversation();
    }
  }

  getMessages(): Message[] {
    return this.conversation?.messages || [];
  }

  getCurrentState(): ConversationState {
    return (this.conversation?.current_state as ConversationState) || 'awaiting_image';
  }
}
