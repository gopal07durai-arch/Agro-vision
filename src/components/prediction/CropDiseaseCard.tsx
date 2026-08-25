import { Leaf, Microscope, CheckCircle2, ShieldAlert } from 'lucide-react';
import type { PredictionResult } from '../../types';
import { ConfidenceIndicator } from './ConfidenceIndicator';
import { SeverityBadge } from './SeverityBadge';
import { getCropIcon, getDiseaseIcon } from '../../utils/diseaseUtils';
import { useLanguage } from '../../i18n';

interface CropDiseaseCardProps {
  prediction: PredictionResult;
  imageDataUrl: string;
}

export function CropDiseaseCard({ prediction, imageDataUrl }: CropDiseaseCardProps) {
  const { t, translateCrop, translateDisease } = useLanguage();
  const { crop, disease, crop_confidence, disease_confidence, severity } = prediction;
  const isHealthy = disease.toLowerCase() === 'healthy';

  const translatedCrop = translateCrop(crop);
  const translatedDisease = translateDisease(disease);

  return (
    <div className="bg-white/95 dark:bg-slate-900/95 backdrop-blur-xl rounded-3xl border border-slate-200/90 dark:border-slate-800 shadow-soft-xl overflow-hidden animate-fade-in-up">
      <div className="grid grid-cols-1 lg:grid-cols-12">
        
        {/* Left: Prominent Uploaded Leaf Image (5 cols) */}
        <div className="lg:col-span-5 relative bg-slate-950 min-h-[260px] sm:min-h-[320px] lg:min-h-full overflow-hidden group">
          <img
            src={imageDataUrl}
            alt="Analyzed crop leaf"
            className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-slate-950/85 via-slate-950/20 to-transparent lg:bg-gradient-to-r lg:from-transparent lg:to-slate-950/50" />
          
          {/* Badge over image */}
          <div className="absolute top-4 left-4">
            <div className="flex items-center gap-2 bg-black/65 backdrop-blur-md text-white px-4 py-2 rounded-full border border-white/20 text-xs font-bold shadow-soft-sm">
              <span className="text-base">{getCropIcon(crop)}</span>
              <span className="tracking-wide">{translatedCrop}</span>
            </div>
          </div>

          <div className="absolute bottom-4 left-4 right-4 flex items-center justify-between text-white/80 text-[11px] font-semibold bg-black/40 backdrop-blur-sm px-3.5 py-1.5 rounded-2xl border border-white/10">
            <span>Leaf Sample Analysis</span>
            <span className="text-emerald-400 font-bold">✓ High Resolution</span>
          </div>
        </div>

        {/* Right: Diagnosis Intelligence & Confidence Scores (7 cols) */}
        <div className="lg:col-span-7 p-6 sm:p-8 flex flex-col justify-between space-y-6">
          
          {/* Diagnostic Details Grid */}
          <div className="space-y-4">
            
            {/* 1. Crop Detected Row */}
            <div className="p-4 rounded-2xl bg-emerald-50/50 dark:bg-emerald-950/20 border border-emerald-100 dark:border-emerald-900/40">
              <div className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider text-emerald-700 dark:text-emerald-300 mb-1">
                <Leaf size={13} className="text-emerald-600" />
                <span>{t('crop_detected')}</span>
              </div>
              <div className="text-xl sm:text-2xl font-black font-display text-slate-900 dark:text-white flex items-center gap-2.5">
                <span className="text-2xl">{getCropIcon(crop)}</span>
                <span className="break-words">{translatedCrop}</span>
              </div>
            </div>

            {/* 2. Disease Identified Row */}
            <div className="p-4 rounded-2xl bg-slate-50/80 dark:bg-slate-800/50 border border-slate-200/80 dark:border-slate-700/80">
              <div className="flex items-center justify-between gap-2 mb-1">
                <div className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider text-purple-700 dark:text-purple-300">
                  <Microscope size={13} className="text-purple-600" />
                  <span>{t('disease_identified')}</span>
                </div>
                <SeverityBadge severity={severity} size="md" />
              </div>

              <div className="flex items-center gap-2.5 mt-1">
                <span className="text-2xl sm:text-3xl flex-shrink-0">{getDiseaseIcon(disease)}</span>
                <h3 className={`text-xl sm:text-2xl font-black font-display tracking-tight leading-tight break-words ${
                  isHealthy ? 'text-emerald-600 dark:text-emerald-400' : 'text-slate-900 dark:text-white'
                }`}>
                  {translatedDisease}
                </h3>
              </div>
            </div>

          </div>

          {/* Bottom Row: Two-Stage Confidence Progress Metrics */}
          <div className="pt-4 border-t border-slate-100 dark:border-slate-800 grid grid-cols-2 gap-3 sm:gap-4">
            
            {/* Crop Confidence Box */}
            <div className="flex flex-col items-center justify-center p-4 rounded-2xl bg-slate-50/70 dark:bg-slate-800/40 border border-slate-200/70 dark:border-slate-700/70 text-center shadow-soft-xs">
              <div className="flex items-center gap-1.5 text-xs font-bold text-slate-600 dark:text-slate-300 mb-3">
                <Leaf size={13} className="text-emerald-500 flex-shrink-0" />
                <span className="truncate">{t('crop_confidence')}</span>
              </div>
              <ConfidenceIndicator value={crop_confidence} size={92} />
            </div>

            {/* Disease Confidence Box */}
            <div className="flex flex-col items-center justify-center p-4 rounded-2xl bg-slate-50/70 dark:bg-slate-800/40 border border-slate-200/70 dark:border-slate-700/70 text-center shadow-soft-xs">
              <div className="flex items-center gap-1.5 text-xs font-bold text-slate-600 dark:text-slate-300 mb-3">
                <Microscope size={13} className="text-purple-500 flex-shrink-0" />
                <span className="truncate">{t('disease_confidence')}</span>
              </div>
              <ConfidenceIndicator value={disease_confidence} size={92} />
            </div>

          </div>

        </div>

      </div>
    </div>
  );
}


