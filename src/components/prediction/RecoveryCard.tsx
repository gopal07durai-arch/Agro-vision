import { Clock, ShieldCheck, HeartHandshake } from 'lucide-react';
import type { DiseaseInfo, SeverityLevel } from '../../types';
import { useLanguage } from '../../i18n';

interface RecoveryCardProps {
  diseaseInfo: DiseaseInfo;
  severity: SeverityLevel;
  disease: string;
}

export function RecoveryCard({ diseaseInfo, disease }: RecoveryCardProps) {
  const { t } = useLanguage();
  const isHealthy = disease.toLowerCase() === 'healthy';

  return (
    <div className="bg-white/90 dark:bg-slate-900/90 backdrop-blur-xl rounded-3xl border border-slate-200/90 dark:border-slate-800 shadow-soft-xl overflow-hidden animate-fade-in-up">
      {/* Header */}
      <div className="p-6 sm:p-8 pb-4 border-b border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-950/30">
        <div className="flex items-center gap-2.5">
          <div className="w-9 h-9 rounded-2xl bg-emerald-50 dark:bg-emerald-950/60 border border-emerald-200 dark:border-emerald-800 flex items-center justify-center text-emerald-600 dark:text-emerald-400">
            <HeartHandshake size={18} />
          </div>
          <div>
            <h3 className="text-base sm:text-lg font-black font-display text-slate-900 dark:text-white leading-tight">
              {t('farmer_action_guide_title')}
            </h3>
            <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">
              {t('farmer_action_guide_subtitle')}
            </p>
          </div>

        </div>
      </div>

      <div className="p-6 sm:p-8 space-y-5">
        {/* Recovery Timeline */}
        {!isHealthy && diseaseInfo.recoveryTime && (
          <div className="p-5 rounded-2xl bg-purple-50/80 dark:bg-purple-950/40 border border-purple-200 dark:border-purple-800/80 flex items-center gap-4">
            <div className="w-12 h-12 rounded-2xl bg-purple-100 dark:bg-purple-900/60 flex items-center justify-center text-purple-600 dark:text-purple-300 flex-shrink-0 shadow-soft-xs">
              <Clock size={22} />
            </div>
            <div>
              <p className="text-[11px] font-bold text-purple-700 dark:text-purple-300 uppercase tracking-wider">
                {t('recovery_time')}
              </p>
              <p className="text-sm sm:text-base font-black font-display text-purple-950 dark:text-purple-100 mt-0.5">
                {diseaseInfo.recoveryTime}
              </p>
            </div>
          </div>
        )}

        {/* Preventive Measures */}
        {diseaseInfo.preventiveMeasures && diseaseInfo.preventiveMeasures.length > 0 && (
          <div className="p-5 rounded-2xl bg-slate-50 dark:bg-slate-800/50 border border-slate-200/80 dark:border-slate-700/80">
            <div className="flex items-center gap-2 mb-3">
              <ShieldCheck size={16} className="text-emerald-500" />
              <p className="text-xs font-bold text-slate-600 dark:text-slate-300 uppercase tracking-wider">
                {t('preventive_measures')}
              </p>
            </div>
            <ul className="space-y-2.5">
              {diseaseInfo.preventiveMeasures.map((measure, i) => (
                <li key={i} className="flex items-start gap-2.5 text-xs sm:text-sm text-slate-700 dark:text-slate-300 font-medium">
                  <span className="w-2 h-2 rounded-full bg-emerald-500 flex-shrink-0 mt-1.5" />
                  <span className="leading-relaxed">{measure}</span>
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>
    </div>
  );
}

