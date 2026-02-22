/*
  # Farmer AI Chatbot Database Schema

  1. New Tables
    - `conversations`
      - `id` (uuid, primary key) - Unique conversation identifier
      - `session_id` (text) - Browser session identifier
      - `messages` (jsonb) - Array of chat messages with roles and content
      - `current_state` (text) - Current conversation state (awaiting_image, collecting_data, etc.)
      - `crop_data` (jsonb) - Detected crop and disease information
      - `soil_data` (jsonb) - Collected soil and climate data
      - `acreage` (numeric) - Cultivation area in acres
      - `created_at` (timestamptz) - Conversation creation timestamp
      - `updated_at` (timestamptz) - Last update timestamp
    
    - `fertilizer_ratings`
      - `id` (uuid, primary key) - Unique rating identifier
      - `fertilizer_name` (text) - Name of the fertilizer
      - `crop_type` (text) - Crop for which fertilizer was recommended
      - `disease_type` (text) - Disease being treated
      - `rating` (integer) - Rating value (1-5)
      - `session_id` (text) - Session that submitted the rating
      - `created_at` (timestamptz) - Rating submission timestamp
    
    - `reminders`
      - `id` (uuid, primary key) - Unique reminder identifier
      - `session_id` (text) - Session to remind
      - `reminder_type` (text) - Type of reminder (apply_fertilizer, upload_followup)
      - `scheduled_at` (timestamptz) - When to send reminder
      - `completed` (boolean) - Whether reminder was acknowledged
      - `created_at` (timestamptz) - Reminder creation timestamp

  2. Security
    - Enable RLS on all tables
    - Add policies for public access (since this is a public chatbot)
*/

-- Create conversations table
CREATE TABLE IF NOT EXISTS conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id text NOT NULL,
  messages jsonb DEFAULT '[]'::jsonb,
  current_state text DEFAULT 'awaiting_image',
  crop_data jsonb DEFAULT '{}'::jsonb,
  soil_data jsonb DEFAULT '{}'::jsonb,
  acreage numeric DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create fertilizer_ratings table
CREATE TABLE IF NOT EXISTS fertilizer_ratings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  fertilizer_name text NOT NULL,
  crop_type text NOT NULL,
  disease_type text NOT NULL,
  rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  session_id text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create reminders table
CREATE TABLE IF NOT EXISTS reminders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id text NOT NULL,
  reminder_type text NOT NULL,
  scheduled_at timestamptz NOT NULL,
  completed boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_conversations_session_id ON conversations(session_id);
CREATE INDEX IF NOT EXISTS idx_fertilizer_ratings_name ON fertilizer_ratings(fertilizer_name);
CREATE INDEX IF NOT EXISTS idx_reminders_session_id ON reminders(session_id);
CREATE INDEX IF NOT EXISTS idx_reminders_scheduled_at ON reminders(scheduled_at);

-- Enable Row Level Security
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE fertilizer_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;

-- Create policies for public access (this is a public chatbot)
CREATE POLICY "Allow all operations on conversations"
  ON conversations
  FOR ALL
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow all operations on fertilizer_ratings"
  ON fertilizer_ratings
  FOR ALL
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow all operations on reminders"
  ON reminders
  FOR ALL
  TO anon
  USING (true)
  WITH CHECK (true);