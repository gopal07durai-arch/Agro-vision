/*
  # Add prediction_history table

  New Table: prediction_history
  - id (uuid, PK)
  - session_id (text) — browser session
  - image_url (text) — base64 data URL or storage URL
  - crop_name (text)
  - disease_name (text)
  - confidence (numeric)
  - severity (text) — Low | Medium | High | None
  - fertilizer_name (text) — primary fertilizer recommended
  - recommendation (jsonb) — full fertilizer + disease info
  - prediction_time_ms (integer)
  - created_at (timestamptz)
*/

CREATE TABLE IF NOT EXISTS prediction_history (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id        text NOT NULL,
  image_url         text,
  crop_name         text NOT NULL,
  disease_name      text NOT NULL,
  confidence        numeric(6,2) NOT NULL,
  severity          text DEFAULT 'Medium',
  fertilizer_name   text,
  recommendation    jsonb DEFAULT '{}'::jsonb,
  prediction_time_ms integer DEFAULT 0,
  created_at        timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_prediction_history_session_id
  ON prediction_history(session_id);

CREATE INDEX IF NOT EXISTS idx_prediction_history_crop_name
  ON prediction_history(crop_name);

CREATE INDEX IF NOT EXISTS idx_prediction_history_created_at
  ON prediction_history(created_at DESC);

-- Enable RLS
ALTER TABLE prediction_history ENABLE ROW LEVEL SECURITY;

-- Public access policy (public chatbot)
CREATE POLICY "Allow all operations on prediction_history"
  ON prediction_history
  FOR ALL
  TO anon
  USING (true)
  WITH CHECK (true);
