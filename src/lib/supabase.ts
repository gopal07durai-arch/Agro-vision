import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

export interface Message {
  role: 'user' | 'assistant';
  content: string;
  imageUrl?: string;
  timestamp: number;
  dropdown?: {
    type: 'soil_type' | 'water_level';
    options: string[];
  };
}

export interface Conversation {
  id: string;
  session_id: string;
  messages: Message[];
  current_state: string;
  crop_data: {
    crop?: string;
    disease?: string;
  };
  soil_data: {
    soilType?: string;
    climate?: string;
    waterLevel?: string;
    soilTemp?: string;
    nitrogen?: string;
    phosphorous?: string;
    potassium?: string;
  };
  acreage: number;
  created_at: string;
  updated_at: string;
}

export interface FertilizerRating {
  id: string;
  fertilizer_name: string;
  crop_type: string;
  disease_type: string;
  rating: number;
  session_id: string;
  created_at: string;
}

export interface Reminder {
  id: string;
  session_id: string;
  reminder_type: string;
  scheduled_at: string;
  completed: boolean;
  created_at: string;
}
