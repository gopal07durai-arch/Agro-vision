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
  | 'presenting_fertilizers'
  | 'awaiting_rating'
  | 'completed';

export const SUPPORTED_CROPS = [
  'Sugarcane',
  'Turmeric',
  'Groundnut',
  'Blackgram',
  'Sunflower',
  'Wheat',
  'Paddy (Rice)',
  'Eggplant (Brinjal)',
  'Cotton',
  'Tomato',
];

const UNSUPPORTED_CROP_RESPONSE =
  'This is an unsupported crop. Please upload an image of one of these supported crops: Sugarcane, Turmeric, Groundnut, Blackgram, Sunflower, Wheat, Paddy (Rice), Eggplant (Brinjal), Cotton, or Tomato.';

export function normalizeCropName(cropName?: string): string | null {
  const normalized = (cropName || '').trim().toLowerCase();
  if (!normalized) return 'Sugarcane';

  const aliasMap: Record<string, string> = {
    sugarcane: 'Sugarcane',
    turmeric: 'Turmeric',
    groundnut: 'Groundnut',
    blackgram: 'Blackgram',
    sunflower: 'Sunflower',
    wheat: 'Wheat',
    paddy: 'Paddy (Rice)',
    rice: 'Paddy (Rice)',
    'paddy (rice)': 'Paddy (Rice)',
    eggplant: 'Eggplant (Brinjal)',
    brinjal: 'Eggplant (Brinjal)',
    'eggplant (brinjal)': 'Eggplant (Brinjal)',
    cotton: 'Cotton',
    tomato: 'Tomato',
  };

  return aliasMap[normalized] || null;
}

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

  private createEmptyConversation(): Conversation {
    return {
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
  }

  async initialize(forceFresh = false): Promise<void> {
    if (forceFresh) {
      this.conversation = this.createEmptyConversation();
      this.useLocalFallback = true;
      this.saveLocalConversation();
      return;
    }

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
      this.conversation = this.createEmptyConversation();

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
      this.conversation = this.createEmptyConversation();
      this.saveLocalConversation();
    }
  }

  private saveLocalConversation() {
    try {
      if (typeof window !== 'undefined') {
        const safeConversation = {
          ...this.conversation,
          messages: (this.conversation?.messages || []).map((message) => ({
            ...message,
            imageUrl: message.imageUrl ? '[image]' : undefined,
          })),
        };
        window.localStorage.setItem(this.localKey, JSON.stringify(safeConversation));
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

  async processImageUpload(imageDataUrl: string, cropHint?: string): Promise<string> {
    if (!this.conversation) await this.initialize();

    const normalizedCropName = normalizeCropName(cropHint);
    if (!normalizedCropName) {
      await this.updateState('awaiting_image');
      await this.addMessage('assistant', UNSUPPORTED_CROP_RESPONSE);
      return UNSUPPORTED_CROP_RESPONSE;
    }

    await this.addMessage('user', 'Uploaded crop image', imageDataUrl);
    await this.updateState('processing_image');

    try {
      const conversationHistory: ChatMessage[] = this.conversation!.messages.map((msg) => ({
        role: msg.role,
        content: msg.content,
      }));

      const analysisResult = await analyzeImageForCropDisease(imageDataUrl, conversationHistory, normalizedCropName);

      const detectedCrop = this.extractCropName(analysisResult);
      const detectedDisease = this.extractDiseaseName(analysisResult);
      const normalizedAnalysis = analysisResult.toLowerCase();

      if (
        normalizedAnalysis.includes('busy') ||
        normalizedAnalysis.includes('temporarily unavailable') ||
        normalizedAnalysis.includes('rate limit') ||
        normalizedAnalysis.includes('quota') ||
        normalizedAnalysis.includes('rejected the request') ||
        normalizedAnalysis.includes('api key') ||
        normalizedAnalysis.includes('no response from ai') ||
        normalizedAnalysis.includes('exhausted') ||
        normalizedAnalysis.includes('could not confidently identify')
      ) {
        await this.updateState('awaiting_image');
        const response = 'I could not confidently identify the crop or disease from this image. Please upload a clear image of one of the supported crops or try again.';
        await this.addMessage('assistant', response);
        return response;
      }

      const looksLikeSupportedCrop = detectedCrop && this.isSupportedCrop(detectedCrop);
      const looksLikeDetection = normalizedAnalysis.includes('i detected') || normalizedAnalysis.includes('detected') || normalizedAnalysis.includes('healthy');

      if (normalizedAnalysis.includes('unsupported crop') || 
          normalizedAnalysis.includes('not supported') ||
          normalizedAnalysis.includes('not in the supported') ||
          normalizedAnalysis.includes('unsupported image')) {
        await this.updateState('awaiting_image');
        await this.addMessage('assistant', UNSUPPORTED_CROP_RESPONSE);
        return UNSUPPORTED_CROP_RESPONSE;
      } else if (looksLikeSupportedCrop && looksLikeDetection) {
        const diseaseName = detectedDisease || 'Unknown disease';
        await this.updateCropData(detectedCrop, diseaseName);
        await this.updateState('collecting_soil_type');

        const response = `${analysisResult}\n\nDetected disease: ${diseaseName}.\n\nGreat! Now, please tell me about your soil and climate conditions so I can recommend the best fertilizers.\n\nFirst, what is your Soil Type?`;

        await this.addMessage('assistant', response, undefined, {
          type: 'soil_type',
          options: SOIL_TYPE_OPTIONS,
        });
        return response;
      } else if (normalizedAnalysis.includes('please upload') ||
                 normalizedAnalysis.includes('unclear') ||
                 normalizedAnalysis.includes('better image')) {
        await this.updateState('awaiting_image');
        await this.addMessage('assistant', analysisResult);
        return analysisResult;
      } else {
        await this.updateState('awaiting_image');
        const response = 'I could not confidently identify the crop or disease from this image. Please upload a clear image of one of the supported crops or try again.';
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

    const loadingResponse = 'Thank you for providing all the information! Let me generate personalized fertilizer recommendations for your crop...';
    await this.addMessage('assistant', loadingResponse);

    const recommendations = await this.generateFertilizerRecommendations();
    await this.updateState('awaiting_rating');

    await this.addMessage('assistant', recommendations);
    const thankYouResponse = 'Thank You! 🙏';
    await this.addMessage('assistant', thankYouResponse);
    return thankYouResponse;
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

  private parseNutrientValue(value?: string): number | null {
    if (!value) return null;
    const cleaned = `${value}`.replace(/[^0-9.\-]/g, '');
    const parsed = Number.parseFloat(cleaned);
    return Number.isFinite(parsed) ? parsed : null;
  }

  private buildBioFertilizerRecommendations(): string {
    const cropData = this.conversation!.crop_data;
    const soilData = this.conversation!.soil_data;

    const crop = cropData.crop || 'your crop';
    const disease = cropData.disease || 'general health';
    const soilType = soilData.soilType || 'Not provided';
    const climate = soilData.climate || 'Not provided';
    const waterLevel = soilData.waterLevel || 'Not provided';
    const soilTemp = this.parseNutrientValue(soilData.soilTemp);
    const nitrogen = this.parseNutrientValue(soilData.nitrogen);
    const phosphorous = this.parseNutrientValue(soilData.phosphorous);
    const potassium = this.parseNutrientValue(soilData.potassium);

    const temperatureLabel = soilTemp !== null ? `${soilTemp.toFixed(1)}°C` : 'Not provided';
    const nitrogenStatus = nitrogen === null ? 'Not provided' : nitrogen < 80 ? 'Low' : nitrogen < 140 ? 'Medium' : 'High';
    const phosphorusStatus = phosphorous === null ? 'Not provided' : phosphorous < 40 ? 'Low' : phosphorous < 80 ? 'Medium' : 'High';
    const potassiumStatus = potassium === null ? 'Not provided' : potassium < 80 ? 'Low' : potassium < 140 ? 'Medium' : 'High';

    const bioRecommendations: string[] = [];

    if (nitrogenStatus === 'Low' || nitrogenStatus === 'Not provided') {
      bioRecommendations.push(
        '- Azospirillum / Azotobacter: Apply 1-2 kg per acre as seed treatment or soil application. Best for low nitrogen and warm climates. Helps improve nitrogen fixation and plant vigor.'
      );
    }

    if (phosphorusStatus === 'Low' || phosphorusStatus === 'Not provided') {
      bioRecommendations.push(
        '- Phosphate Solubilizing Bacteria (PSB): Apply 1-2 kg per acre mixed in compost or soil. Useful for low phosphorus and light soils. Improves phosphorus availability.'
      );
    }

    if (potassiumStatus === 'Low' || potassiumStatus === 'Not provided') {
      bioRecommendations.push(
        '- Potash Mobilizing Bacteria (KMB): Apply 1-2 kg per acre with farmyard manure. Useful when potassium is low and irrigation is regular. Improves stress tolerance.'
      );
    }

    if (disease.toLowerCase().includes('blight') || disease.toLowerCase().includes('rot') || disease.toLowerCase().includes('mildew') || disease.toLowerCase().includes('rust') || disease.toLowerCase().includes('wilt')) {
      bioRecommendations.push(
        '- Trichoderma viride / Pseudomonas fluorescens: Apply 4-5 g per kg seed or 2.5 kg per acre as soil drench. Good for fungal disease pressure and humid weather.'
      );
    }

    if ((soilTemp !== null && soilTemp >= 28) || climate.toLowerCase().includes('tropical') || climate.toLowerCase().includes('subtropical')) {
      bioRecommendations.push(
        '- Mycorrhizal biofertilizer: Apply near roots during transplanting or early growth. Useful for warm climates and drip/sprinkler irrigation. Improves water and nutrient uptake.'
      );
    }

    if (bioRecommendations.length === 0) {
      bioRecommendations.push(
        '- Rhizobium / PGPR mix: Apply 1-2 kg per acre as seed or soil treatment. Good general support for healthy root development and balanced nutrient use.'
      );
    }

    return `Based on your crop, soil, climate, and irrigation details, here are practical bio-fertilizer recommendations for ${crop}.

Crop: ${crop}
Soil type: ${soilType}
Climate code: ${climate}
Water / irrigation: ${waterLevel}
Soil temperature: ${temperatureLabel}
N status: ${nitrogenStatus}
P status: ${phosphorusStatus}
K status: ${potassiumStatus}

Bio-fertilizers:
${bioRecommendations.join('\n')}

General guidance:
- Apply biofertilizers in the morning or evening.
- Mix them with compost or farmyard manure for better survival.
- Use drip or sprinkler irrigation for better root contact.
- Avoid applying chemical fungicides immediately after biofertilizer treatment.

`;
  }

  private async generateFertilizerRecommendations(): Promise<string> {
    return this.buildBioFertilizerRecommendations();
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
    const supportedDiseases = [
      'anthracnose', 'healthy', 'leaf crinckle', 'powdery mildew', 'yellow mosaic',
      'aphids', 'army worm', 'bacterial blight', 'target spot',
      'leaf spot', 'mosaic virus', 'small leaf', 'white mold', 'wilt disease',
      'late leaf spot', 'leaf blight', 'brown spot', 'leaf blast', 'leaf scald', 'sheath blight',
      'redrot', 'redrust',
      'alternaria sunflower', 'downy mildew sunflower', 'rhizopus', 'sclerotinia',
      'bacterial spot', 'early blight', 'late blight', 'leaf mold', 'septoria leaf spot', 'spider mites', 'yellow leaf curl virus',
      'dry leaf', 'leaf blotch', 'rhizome disease root',
      'wheat crown root rot', 'wheat healthy', 'wheat leaf rust', 'wheat loose smut'
    ];

    const lower = (text || '').toLowerCase();
    for (const label of supportedDiseases) {
      if (lower.includes(label)) {
        // Return with original casing from the list (simple capitalization)
        return label;
      }
    }

    // Fallback: try to extract short phrase after 'with' or 'has'
    const match = text.match(/\b(?:with|has|showing|shows)\s+([A-Za-z\s]+?)(?=[\.\!?]|$)/i);
    if (match && match[1]) return match[1].trim();

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

  async clearHistory(): Promise<void> {
    this.conversation = this.createEmptyConversation();
    this.useLocalFallback = true;
    this.saveLocalConversation();
  }

  getMessages(): Message[] {
    return this.conversation?.messages || [];
  }

  getCurrentState(): ConversationState {
    return (this.conversation?.current_state as ConversationState) || 'awaiting_image';
  }
}
