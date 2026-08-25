/*
  # Add crop_confidence and disease_confidence columns

  Two-stage model inference returns separate confidence values:
  - crop_confidence    (Stage 1: sum of probs across all crop disease classes)
  - disease_confidence (Stage 2: argmax class probability)

  We keep the legacy `confidence` column for backward compatibility with
  existing rows (mapped to disease_confidence for new inserts).
*/

ALTER TABLE prediction_history
  ADD COLUMN IF NOT EXISTS crop_confidence    numeric(6,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS disease_confidence numeric(6,2) DEFAULT 0;

-- Backfill: populate disease_confidence from legacy confidence column for old rows
UPDATE prediction_history
  SET disease_confidence = confidence
WHERE disease_confidence = 0 AND confidence IS NOT NULL;

-- Backfill: populate crop_confidence to match disease_confidence for old rows
-- (best approximation since crop_confidence wasn't tracked before)
UPDATE prediction_history
  SET crop_confidence = confidence
WHERE crop_confidence = 0 AND confidence IS NOT NULL;

-- Indexes for confidence-based queries
CREATE INDEX IF NOT EXISTS idx_prediction_history_crop_confidence
  ON prediction_history(crop_confidence DESC);

CREATE INDEX IF NOT EXISTS idx_prediction_history_disease_confidence
  ON prediction_history(disease_confidence DESC);
