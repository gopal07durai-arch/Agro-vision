import { useState } from 'react';
import { ChevronDown, ChevronUp, AlertCircle, CheckCircle2, FlaskConical, Clock, Layers } from 'lucide-react';
import type { FertilizerRecommendation } from '../../types';
import { useLanguage } from '../../i18n';

interface FertilizerCardProps {
  fertilizer: FertilizerRecommendation;
  index: number;
}

export function FertilizerCard({ fertilizer, index }: FertilizerCardProps) {
  const { t } = useLanguage();
  const [expanded, setExpanded] = useState(index === 0);

  const translatedType =
    fertilizer.type === 'Bio' ? t('type_bio') :
      fertilizer.type === 'Chemical' ? t('type_chemical') :
        t('type_organic');

  return (
    <div className="rounded-3xl border border-slate-200/90 dark:border-slate-800 bg-white/90 dark:bg-slate-900/90 backdrop-blur-xl overflow-hidden shadow-soft-sm transition-all duration-300">
      {/* Clickable Header */}
      <button
        type="button"
        onClick={() => setExpanded(e => !e)}
        className="w-full flex items-center justify-between p-5 sm:p-6 text-left hover:bg-slate-50/50 dark:hover:bg-slate-800/40 transition-colors"
      >
        <div className="flex items-center gap-3.5 min-w-0">
          <div className="w-12 h-12 rounded-2xl bg-emerald-50 dark:bg-emerald-950/60 border border-emerald-200 dark:border-emerald-800 flex items-center justify-center text-2xl flex-shrink-0 shadow-soft-xs">
            {fertilizer.icon || '🌱'}
          </div>

          <div className="min-w-0">
            <div className="flex items-center gap-2 flex-wrap mb-1">
              <h4 className="font-bold font-display text-slate-900 dark:text-white text-sm sm:text-base leading-tight">
                {fertilizer.name}
              </h4>
              <span className="text-[11px] px-2.5 py-0.5 rounded-full font-bold bg-emerald-100 dark:bg-emerald-950/80 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800">
                {translatedType}
              </span>
            </div>

            <p className="text-xs text-slate-500 dark:text-slate-400 font-medium break-words leading-relaxed">
              {t('dosage')}: <strong className="text-slate-700 dark:text-slate-200">{fertilizer.dosage}</strong>
            </p>

          </div>
        </div>

        <div className="p-2 rounded-xl text-slate-400 dark:text-slate-500 bg-slate-100 dark:bg-slate-800 flex-shrink-0 ml-2">
          {expanded ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
        </div>
      </button>

      {/* Expanded Details Body */}
      {expanded && (
        <div className="p-5 sm:p-6 pt-0 space-y-4 border-t border-slate-100 dark:border-slate-800 mt-1">
          
          {/* Quick Specifications Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-4">
            <div className="bg-slate-50 dark:bg-slate-800/60 border border-slate-200/60 dark:border-slate-700/60 rounded-2xl p-4">
              <p className="text-[11px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider mb-1.5 flex items-center gap-1.5">
                <Layers size={13} className="text-emerald-500" />
                <span>{t('application_method')}</span>
              </p>
              <p className="text-xs sm:text-sm font-bold text-slate-800 dark:text-slate-200">
                {fertilizer.applicationMethod}
              </p>
            </div>

            <div className="bg-slate-50 dark:bg-slate-800/60 border border-slate-200/60 dark:border-slate-700/60 rounded-2xl p-4">
              <p className="text-[11px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider mb-1.5 flex items-center gap-1.5">
                <Clock size={13} className="text-blue-500" />
                <span>{t('frequency')} / Timing</span>
              </p>
              <p className="text-xs sm:text-sm font-bold text-slate-800 dark:text-slate-200">
                {fertilizer.frequency}
              </p>
            </div>
          </div>

          {/* Benefits */}
          {fertilizer.benefits && fertilizer.benefits.length > 0 && (
            <div className="p-4 rounded-2xl bg-emerald-50/50 dark:bg-emerald-950/20 border border-emerald-100 dark:border-emerald-900/40">
              <p className="text-xs font-bold text-emerald-800 dark:text-emerald-300 uppercase tracking-wider mb-2 flex items-center gap-1.5">
                <CheckCircle2 size={14} className="text-emerald-600 dark:text-emerald-400" />
                <span>{t('benefits')}</span>
              </p>
              <ul className="space-y-1.5">
                {fertilizer.benefits.map((b, i) => (
                  <li key={i} className="flex items-start gap-2 text-xs sm:text-sm text-emerald-950 dark:text-emerald-200 font-medium">
                    <span className="text-emerald-500 font-bold">✓</span>
                    <span>{b}</span>
                  </li>
                ))}
              </ul>
            </div>
          )}

          {/* Precautions */}
          {fertilizer.precautions && fertilizer.precautions.length > 0 && (
            <div className="p-4 rounded-2xl bg-amber-50/50 dark:bg-amber-950/20 border border-amber-100 dark:border-amber-900/40">
              <p className="text-xs font-bold text-amber-800 dark:text-amber-300 uppercase tracking-wider mb-2 flex items-center gap-1.5">
                <AlertCircle size={14} className="text-amber-600 dark:text-amber-400" />
                <span>{t('precautions')}</span>
              </p>
              <ul className="space-y-1.5">
                {fertilizer.precautions.map((p, i) => (
                  <li key={i} className="flex items-start gap-2 text-xs sm:text-sm text-amber-950 dark:text-amber-200 font-medium">
                    <span className="text-amber-500 font-bold">⚠️</span>
                    <span>{p}</span>
                  </li>
                ))}
              </ul>
            </div>
          )}

        </div>
      )}
    </div>
  );
}

