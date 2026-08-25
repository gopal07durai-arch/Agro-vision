import { useEffect, useState } from 'react';
import { ScanSearch, Cpu, Sparkles, CheckCircle2, ShieldAlert } from 'lucide-react';
import { useLanguage } from '../../i18n';
import type { TranslationKey } from '../../i18n/types';

interface AnalyzingLoaderProps {
  step: 'compressing' | 'quality_check' | 'validating' | 'predicting' | 'explaining';
  progress: number;
  statusMessage: string;
  imageDataUrl: string | null;
}

const MASTER_STEPS: Array<{ key: string; icon: typeof ScanSearch; labelKey: TranslationKey }> = [
  { key: 'compressing',   icon: ScanSearch,   labelKey: 'scan_step_scanning' },
  { key: 'quality_check', icon: Cpu,          labelKey: 'scan_step_crop_chars' },
  { key: 'validating',    icon: ShieldAlert,  labelKey: 'scan_step_disease_patterns' },
  { key: 'predicting',    icon: Sparkles,     labelKey: 'scan_step_diagnosis' },
];

export function AnalyzingLoader({ step, progress, imageDataUrl }: AnalyzingLoaderProps) {
  const { t } = useLanguage();
  const [dotCount, setDotCount] = useState(1);
  const [elapsed, setElapsed] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => setDotCount(d => (d % 3) + 1), 400);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    const timer = setInterval(() => setElapsed(e => e + 1), 1000);
    return () => clearInterval(timer);
  }, []);

  const stepMapping: Record<string, number> = {
    compressing: 0,
    quality_check: 1,
    validating: 2,
    predicting: 3,
    explaining: 3,
  };

  const currentIdx = stepMapping[step] ?? 0;

  return (
    <div className="min-h-[85vh] flex flex-col items-center justify-center py-12 px-4 relative z-10">
      <div className="w-full max-w-md bg-white/90 dark:bg-slate-900/90 backdrop-blur-xl rounded-3xl border border-slate-200/90 dark:border-slate-800 shadow-soft-xl p-8 sm:p-10 text-center animate-fade-in-up">
        
        {/* Leaf Preview with Laser Scanner Sweep */}
        {imageDataUrl && (
          <div className="relative w-32 h-32 mx-auto mb-6 rounded-2xl overflow-hidden border-2 border-emerald-500 shadow-glow-green bg-slate-950">
            <img
              src={imageDataUrl}
              alt="Analyzing leaf"
              className="w-full h-full object-cover"
            />
            <div className="absolute inset-0 bg-emerald-950/20">
              <div className="laser-scanner-line" />
            </div>
          </div>
        )}

        {/* Title */}
        <h2 className="text-2xl font-black font-display text-slate-900 dark:text-white mb-1.5 tracking-tight">
          🌿 {t('analyzing_title')}{'.'.repeat(dotCount)}
        </h2>
        
        <p className="text-xs font-semibold text-emerald-600 dark:text-emerald-400 mb-6">
          {t(MASTER_STEPS[currentIdx]?.labelKey ?? 'scan_step_scanning')}
        </p>

        {/* Progress Bar */}
        <div className="mb-6">
          <div className="flex justify-between text-xs font-bold text-slate-500 dark:text-slate-400 mb-2">
            <span>{t('progress')}</span>
            <span>{Math.min(progress, 100)}% ({elapsed}s)</span>
          </div>
          <div className="w-full h-2.5 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden p-0.5 border border-slate-200/60 dark:border-slate-700/60">
            <div
              className="h-full bg-gradient-to-r from-emerald-500 to-green-500 rounded-full transition-all duration-500 shadow-sm"
              style={{ width: `${Math.min(progress, 100)}%` }}
            />
          </div>
        </div>

        {/* Step Items */}
        <div className="space-y-2.5 text-left">
          {MASTER_STEPS.map((s, i) => {
            const Icon = s.icon;
            const isDone = i < currentIdx;
            const isActive = i === currentIdx;
            const isPending = i > currentIdx;

            return (
              <div
                key={s.key}
                className={`
                  flex items-center gap-3 p-3 rounded-2xl border transition-all duration-300
                  ${isActive
                    ? 'bg-emerald-50/80 dark:bg-emerald-950/50 border-emerald-300 dark:border-emerald-700 shadow-soft-sm scale-[1.02]'
                    : isDone
                      ? 'bg-slate-50 dark:bg-slate-800/40 border-slate-200/60 dark:border-slate-700/60 opacity-90'
                      : 'bg-slate-50/40 dark:bg-slate-800/20 border-slate-200/30 dark:border-slate-800/30 opacity-40'
                  }
                `}
              >
                <div className={`
                  w-8 h-8 rounded-xl flex items-center justify-center flex-shrink-0 transition-colors
                  ${isDone
                    ? 'bg-emerald-500 text-white shadow-soft-xs'
                    : isActive
                      ? 'bg-emerald-500 text-white animate-pulse shadow-glow-green'
                      : 'bg-slate-200 dark:bg-slate-700 text-slate-400'
                  }
                `}>
                  {isDone ? <CheckCircle2 size={16} /> : <Icon size={16} />}
                </div>

                <div className="min-w-0 flex-1">
                  <p className={`text-xs font-bold ${
                    isActive
                      ? 'text-emerald-900 dark:text-emerald-200'
                      : isDone
                        ? 'text-slate-800 dark:text-slate-200'
                        : 'text-slate-400 dark:text-slate-500'
                  }`}>
                    {t(s.labelKey)}
                  </p>
                </div>
              </div>
            );
          })}
        </div>

      </div>
    </div>
  );
}

