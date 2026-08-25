import { FlaskConical, Layers } from 'lucide-react';
import type { PredictionResult, FertilizerRecommendation, DiseaseInfo } from '../../types';
import { CropDiseaseCard } from './CropDiseaseCard';
import { FertilizerCard } from './FertilizerCard';
import { DiseaseInfoCard } from './DiseaseInfoCard';
import { RecoveryCard } from './RecoveryCard';
import { ActionBar } from './ActionBar';
import { saveRating } from '../../services/supabaseService';
import { useLanguage } from '../../i18n';

interface PredictionPageProps {
  prediction: PredictionResult;
  fertilizers: FertilizerRecommendation[];
  diseaseInfo: DiseaseInfo | null;
  imageDataUrl: string;
  sessionId: string;
  onStartChat: () => void;
  onReset: () => void;
  onDownload: () => void;
}

export function PredictionPage({
  prediction,
  fertilizers,
  diseaseInfo,
  imageDataUrl,
  sessionId,
  onStartChat,
  onReset,
  onDownload,
}: PredictionPageProps) {
  const { t } = useLanguage();

  const handleRate = async (rating: number) => {
    const primaryFertilizer = prediction.fertilizer ?? fertilizers[0]?.name ?? 'General Bio Fertilizer';
    await saveRating(sessionId, prediction.crop, prediction.disease, primaryFertilizer, rating);
  };

  return (
    <div className="relative z-10 pb-40 pt-6 sm:pt-8 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto space-y-6 sm:space-y-8">


        {/* 1. Prominent Crop & Disease Result Identity */}
        <CropDiseaseCard prediction={prediction} imageDataUrl={imageDataUrl} />

        {/* 2. Disease Intelligence Report (Pathology, Symptoms, Controls) */}
        <DiseaseInfoCard
          diseaseInfo={diseaseInfo}
          isLoading={!diseaseInfo}
          crop={prediction.crop}
          disease={prediction.disease}
        />

        {/* 3. Recovery Timeline & Preventive Protocol */}
        {diseaseInfo && (
          <RecoveryCard
            diseaseInfo={diseaseInfo}
            severity={prediction.severity}
            disease={prediction.disease}
          />
        )}

        {/* 4. Fertilizer & Nutrition Recommendations */}
        {fertilizers.length > 0 && (
          <div className="bg-white/90 dark:bg-slate-900/90 backdrop-blur-xl rounded-3xl border border-slate-200/90 dark:border-slate-800 shadow-soft-xl overflow-hidden animate-fade-in-up">
            <div className="p-6 sm:p-8 pb-4 border-b border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-950/30 flex items-center justify-between gap-3">
              <div className="flex items-center gap-2.5">
                <div className="w-9 h-9 rounded-2xl bg-emerald-50 dark:bg-emerald-950/60 border border-emerald-200 dark:border-emerald-800 flex items-center justify-center text-emerald-600 dark:text-emerald-400">
                  <FlaskConical size={18} />
                </div>
                <div>
                  <h3 className="text-base sm:text-lg font-black font-display text-slate-900 dark:text-white leading-tight">
                    {t('treatment_recommendations')}
                  </h3>
                  <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">
                    {t('fertilizer_section_subtitle')}
                  </p>

                </div>
              </div>

              <span className="text-[11px] font-bold text-emerald-700 dark:text-emerald-300 bg-emerald-100/80 dark:bg-emerald-950/80 px-3 py-1 rounded-full border border-emerald-200 dark:border-emerald-800">
                {fertilizers.length} {t('options_count')}
              </span>
            </div>

            <div className="p-6 sm:p-8 space-y-4">
              {fertilizers.map((f, i) => (
                <FertilizerCard key={`${f.name}-${i}`} fertilizer={f} index={i} />
              ))}
            </div>
          </div>
        )}

        {/* Spacer */}
        <div className="h-4" />
      </div>

      {/* Sticky Action Bar */}
      <ActionBar
        onChat={onStartChat}
        onReset={onReset}
        onDownload={onDownload}
        onRate={handleRate}
      />
    </div>
  );
}

