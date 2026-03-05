import { useState, useEffect, useRef } from 'react';
import { ChatMessage } from './ChatMessage';
import { ChatInput } from './ChatInput';
import { Translator } from './Translator';
import { ConversationManager } from '../lib/conversationManager';
import { Message } from '../lib/supabase';
import { Sprout } from 'lucide-react';

// Helper function to determine climate based on latitude
function determineClimate(latitude: number): string {
  // Tropical (between Tropics of Cancer and Capricorn)
  if (Math.abs(latitude) <= 23.5) {
    return 'Tropical';
  }
  // Subtropical
  if (Math.abs(latitude) > 23.5 && Math.abs(latitude) <= 35) {
    return 'Subtropical';
  }
  // Temperate
  if (Math.abs(latitude) > 35 && Math.abs(latitude) <= 55) {
    return 'Temperate';
  }
  // Polar/Cold
  return 'Polar/Cold';
}

// Function to get user's climate based on geolocation
function getClimateFromGeolocation(): Promise<string> {
  return new Promise((resolve) => {
    if ('geolocation' in navigator) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const { latitude } = position.coords;
          const climate = determineClimate(latitude);
          resolve(climate);
        },
        () => {
          // Default to Temperate if geolocation fails
          resolve('Temperate');
        }
      );
    } else {
      // Default to Temperate if geolocation not available
      resolve('Temperate');
    }
  });
}

export function Chat() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  const [sessionId] = useState(() => {
    const stored = localStorage.getItem('farmer-chatbot-session');
    if (stored) return stored;
    const newId = `session-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    localStorage.setItem('farmer-chatbot-session', newId);
    return newId;
  });

  const conversationManagerRef = useRef<ConversationManager | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // ---------------- INIT ----------------
  useEffect(() => {
    const initConversation = async () => {
      try {
        const manager = new ConversationManager(sessionId);
        
        // Auto-detect climate and get location coordinates
        const detectedClimate = await getClimateFromGeolocation();
        manager.setAutoDetectedClimate(detectedClimate);
        
        // Get coordinates for soil temperature cloud fetch
        if ('geolocation' in navigator) {
          navigator.geolocation.getCurrentPosition((position) => {
            const { latitude, longitude } = position.coords;
            manager.setUserLocation(latitude, longitude);
          });
        }
        
        await manager.initialize();
        conversationManagerRef.current = manager;

        const existingMessages = manager.getMessages();
        if (existingMessages.length > 0) {
          setMessages(existingMessages);
        } else {
          const welcomeMessage: Message = {
            role: 'assistant',
            content:
              `Hello! I am your Farmer AI Assistant. 🌱

I can help you identify crop diseases and recommend fertilizers.

📌 Please upload a clear crop leaf image taken in good lighting.

Supported crops:
Sugarcane, Turmeric, Groundnut, Blackgram, Sunflower, Wheat, Paddy (Rice), Eggplant (Brinjal), Cotton, Tomato.`,
            timestamp: Date.now(),
          };

          await manager.addMessage('assistant', welcomeMessage.content);
          setMessages([welcomeMessage]);
        }
      } catch (err) {
        console.error('Failed to initialize conversation:', err);
        const userMessage: Message = {
          role: 'assistant',
          content:
            'Unable to connect to the backend. Please check your network and Supabase project URL (VITE_SUPABASE_URL) and restart the dev server.',
          timestamp: Date.now(),
        };
        setMessages((prev) => [...prev, userMessage]);
      }
    };

    initConversation();
  }, [sessionId]);

  // ---------------- AUTO SCROLL ----------------
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  // ---------------- SEND TEXT ----------------
  const handleSendMessage = async (messageText: string) => {
    if (!conversationManagerRef.current || !messageText.trim()) return;

    setIsLoading(true);
    try {
      await conversationManagerRef.current.processTextInput(messageText);
      setMessages([...conversationManagerRef.current.getMessages()]);
    } catch (error) {
      console.error('Text error:', error);
      addErrorMessage('I had trouble processing your message. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  // ---------------- HANDLE DROPDOWN SELECTION ----------------
  const handleDropdownSelect = async (value: string) => {
    await handleSendMessage(value);
  };

  // ---------------- SEND IMAGE ----------------
  const handleSendImage = async (imageDataUrl: string) => {
    if (!conversationManagerRef.current) return;

    setIsLoading(true);
    try {
      await conversationManagerRef.current.processImageUpload(imageDataUrl);
      setMessages([...conversationManagerRef.current.getMessages()]);
    } catch (error) {
      console.error('Image error:', error);
      addErrorMessage(
        'I encountered an error analyzing your image. Please upload a clear crop leaf photo taken in daylight.'
      );
    } finally {
      setIsLoading(false);
    }
  };

  // ---------------- ERROR MESSAGE ----------------
  const addErrorMessage = (text: string) => {
    const errorMessage: Message = {
      role: 'assistant',
      content: text,
      timestamp: Date.now(),
    };
    setMessages((prev) => [...prev, errorMessage]);
  };

  return (
    <div className="flex flex-col h-screen bg-gradient-to-br from-green-50 to-blue-50">

      {/* HEADER */}
      <header className="bg-gradient-to-r from-green-600 to-green-700 text-white shadow-lg">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between gap-3">
            <div className="flex items-center gap-3">
              <div className="bg-white/20 p-2 rounded-lg">
                <Sprout size={28} />
              </div>
              <div>
                <h1 className="text-2xl font-bold">Farmer AI Chatbot</h1>
                <p className="text-sm text-green-100">Your Smart Farming Assistant</p>
              </div>
            </div>
            <Translator />
          </div>
        </div>
      </header>

      {/* MESSAGES */}
      <div 
        className="flex-1 overflow-y-auto relative"
        style={{
          backgroundImage: 'url(https://png.pngtree.com/thumb_back/fh260/background/20240610/pngtree-concept-use-of-the-smart-farmer-system-came-to-help-analysis-image_15746624.jpg)',
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          backgroundRepeat: 'no-repeat',
          backgroundAttachment: 'fixed',
        }}
      >
        {/* Overlay to make text readable */}
        <div className="absolute inset-0 bg-white/40 pointer-events-none" />
        <div className="container mx-auto px-4 py-6 max-w-4xl relative z-10">
          {messages.map((message, index) => (
            <ChatMessage key={index} message={message} onDropdownSelect={handleDropdownSelect} />
          ))}

          {isLoading && (
            <div className="flex justify-start mb-4">
              <div className="bg-white shadow-md border rounded-2xl px-4 py-3">
                <div className="flex items-center gap-2">
                  <div className="flex gap-1">
                    <div className="w-2 h-2 bg-green-600 rounded-full animate-bounce" />
                    <div className="w-2 h-2 bg-green-600 rounded-full animate-bounce delay-150" />
                    <div className="w-2 h-2 bg-green-600 rounded-full animate-bounce delay-300" />
                  </div>
                  <span className="text-sm text-gray-600">Analyzing...</span>
                </div>
              </div>
            </div>
          )}

          <div ref={messagesEndRef} />
        </div>
      </div>

      {/* INPUT */}
      <div className="container mx-auto px-4 max-w-4xl">
        <ChatInput
          onSendMessage={handleSendMessage}
          onSendImage={handleSendImage}
          disabled={isLoading}
          placeholder={
            conversationManagerRef.current?.getCurrentState() === 'awaiting_image'
              ? 'Upload a crop leaf image...'
              : 'Type your message...'
          }
        />
      </div>

    </div>
  );
}
