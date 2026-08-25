import type { PredictionHistoryEntry } from '../../types';
import { useLanguage } from '../../i18n';
import { getCropIcon, getDiseaseIcon } from '../../utils/diseaseUtils';

interface HistoryCardProps {
  entry: PredictionHistoryEntry;
  index: number;
}

const SEVERITY_BG: Record<string, { bg: string; text: string; border: string }> = {
  High:   { bg: 'bg-rose-50 dark:bg-rose-950/60', text: 'text-rose-700 dark:text-rose-300', border: 'border-rose-200 dark:border-rose-800' },
  Medium: { bg: 'bg-amber-50 dark:bg-amber-950/60', text: 'text-amber-700 dark:text-amber-300', border: 'border-amber-200 dark:border-amber-800' },
  Low:    { bg: 'bg-blue-50 dark:bg-blue-950/60', text: 'text-blue-700 dark:text-blue-300', border: 'border-blue-200 dark:border-blue-800' },
  None:   { bg: 'bg-emerald-50 dark:bg-emerald-950/60', text: 'text-emerald-700 dark:text-emerald-300', border: 'border-emerald-200 dark:border-emerald-800' },
};

function formatDate(isoString: string): string {
  try {
    const d = new Date(isoString);
    return d.toLocaleDateString(undefined, {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch {
    return isoString;
  }
}

export function HistoryCard({ entry, index }: HistoryCardProps) {
  const { t, translateCrop, translateDisease, translateSeverity } = useLanguage();
  const severityStyle = SEVERITY_BG[entry.severity] ?? SEVERITY_BG.Medium;
  const isHealthy = entry.disease_name.toLowerCase() === 'healthy';

  const translatedCrop = translateCrop(entry.crop_name);
  const translatedDisease = translateDisease(entry.disease_name);
  const translatedSeverity = translateSeverity(entry.severity);
  const confValue = entry.disease_confidence || entry.crop_confidence || 0;

  return (
    <div
      className="bg-white/90 dark:bg-slate-900/90 backdrop-blur-xl rounded-3xl border border-slate-200/90 dark:border-slate-800 p-5 shadow-soft-sm hover:shadow-soft-md transition-all animate-fade-in-up"
      style={{ animationDelay: `${index * 50}ms` }}
    >
      <div className="flex items-start gap-4">
        {/* Crop Icon */}
        <div className="flex-shrink-0 w-12 h-12 rounded-2xl bg-emerald-50 dark:bg-emerald-950/60 border border-emerald-200 dark:border-emerald-800 flex items-center justify-center text-2xl shadow-soft-xs">
          {getCropIcon(entry.crop_name)}
        </div>

        {/* Main Info */}
        <div className="flex-1 min-w-0">
          <div className="flex items-start justify-between gap-2 mb-2">
            <div>
              <p className="text-xs font-bold text-emerald-600 dark:text-emerald-400 uppercase tracking-wider">
                {translatedCrop}
              </p>
              <h4 className={`text-base font-black font-display tracking-tight leading-tight ${
                isHealthy ? 'text-emerald-600 dark:text-emerald-400' : 'text-slate-900 dark:text-white'
              }`}>
                {translatedDisease}
              </h4>
            </div>

            {/* Severity badge */}
            <span className={`text-[11px] font-bold px-3 py-1 rounded-full border ${severityStyle.bg} ${severityStyle.text} ${severityStyle.border}`}>
              {translatedSeverity}
            </span>
          </div>

          {/* Confidence bar */}
          {confValue > 0 && (
            <div className="mb-3">
              <div className="flex justify-between text-[11px] text-slate-500 dark:text-slate-400 font-semibold mb-1">
                <span>{t('confidence_score')}</span>
                <span className="text-emerald-600 dark:text-emerald-400 font-bold">
                  {confValue.toFixed(1)}%
                </span>
              </div>
              <div className="w-full h-1.5 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                <div
                  className="h-full bg-gradient-to-r from-emerald-500 to-green-500 rounded-full transition-all duration-500"
                  style={{ width: `${Math.min(confValue, 100)}%` }}
                />
              </div>
            </div>
          )}

          {/* Fertilizer & Timestamp */}
          <div className="flex items-center justify-between gap-2 text-xs text-slate-500 dark:text-slate-400 font-medium">
            <span className="truncate flex items-center gap-1">
              <span>🌱</span>
              <span className="truncate">{entry.fertilizer_name}</span>
            </span>
            <span className="flex-shrink-0 text-[11px] text-slate-400 dark:text-slate-500">
              {formatDate(entry.created_at)}
            </span>
          </div>

          {/* Star rating */}
          {entry.user_rating != null && entry.user_rating > 0 && (
            <div className="flex items-center gap-1 mt-2">
              {[1, 2, 3, 4, 5].map(star => (
                <span key={star} className={`text-xs ${star <= entry.user_rating! ? 'text-amber-400' : 'text-slate-300 dark:text-slate-700'}`}>
                  ★
                </span>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

