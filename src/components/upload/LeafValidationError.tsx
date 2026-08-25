import { AlertTriangle, Upload, RefreshCw, Sun, Leaf, Camera, Eye } from 'lucide-react';
import { useLanguage } from '../../i18n';

interface LeafValidationErrorProps {
  reason: string;
  quality: string;
  onRetry: () => void;
  onCameraClick?: () => void;
}

export function LeafValidationError({ reason, onRetry }: LeafValidationErrorProps) {
  const { t } = useLanguage();

  const DIAGNOSIS_TIPS = [
    { icon: <Sun size={15} className="text-amber-500" />,   text: t('tip_natural_lighting') },
    { icon: <Leaf size={15} className="text-emerald-500" />,  text: t('tip_single_crop_leaf') },
    { icon: <Camera size={15} className="text-blue-500" />,   text: t('tip_camera_steady') },
    { icon: <Eye size={15} className="text-purple-500" />,   text: t('tip_complete_leaf_visible') },
  ];

  return (
    <div className="w-full max-w-lg mx-auto py-8 px-4 animate-fade-in-up">
      <div className="rounded-3xl border border-rose-200/90 dark:border-rose-900/60 bg-white/90 dark:bg-slate-900/90 backdrop-blur-xl overflow-hidden shadow-soft-xl">
        
        {/* Diagnostic Header */}
        <div className="p-8 text-center border-b border-rose-100 dark:border-rose-950/60 bg-rose-50/50 dark:bg-rose-950/20">
          <div className="w-16 h-16 rounded-3xl bg-rose-100 dark:bg-rose-900/40 border border-rose-200 dark:border-rose-800 flex items-center justify-center mx-auto mb-4 text-rose-600 dark:text-rose-400 shadow-soft-sm">
            <AlertTriangle size={32} />
          </div>

          <h3 className="text-2xl font-black font-display text-slate-900 dark:text-white mb-2">
            ❌ {t('validation_error_title')}
          </h3>

          <p className="text-sm text-slate-600 dark:text-slate-300 font-medium max-w-md mx-auto leading-relaxed">
            {reason || t('unsupported_crop_desc')}
          </p>
        </div>

        {/* Tips for Accurate Diagnosis */}
        <div className="p-6 sm:p-8">
          <div className="flex items-center gap-2 mb-4">
            <span className="w-2 h-2 rounded-full bg-emerald-500" />
            <h4 className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              {t('tips_accurate_diagnosis_title')}
            </h4>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {DIAGNOSIS_TIPS.map((tip, idx) => (
              <div
                key={idx}
                className="flex items-center gap-3 p-3 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200/60 dark:border-slate-700/60 text-xs font-semibold text-slate-700 dark:text-slate-300"
              >
                <div className="w-7 h-7 rounded-xl bg-white dark:bg-slate-900 flex items-center justify-center flex-shrink-0 shadow-soft-xs">
                  {tip.icon}
                </div>
                <span>{tip.text}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Actions */}
        <div className="p-6 sm:p-8 pt-0 flex flex-col sm:flex-row gap-3">
          <button
            type="button"
            onClick={onRetry}
            className="flex-1 h-12 flex items-center justify-center gap-2 px-6 bg-gradient-to-r from-emerald-600 to-green-600 hover:from-emerald-500 hover:to-green-500 text-white rounded-2xl font-bold text-sm shadow-glow-green active:scale-95 transition-all"
          >
            <Upload size={16} />
            <span>{t('btn_upload_another')}</span>
          </button>

          <button
            type="button"
            onClick={onRetry}
            className="h-12 px-6 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-300 rounded-2xl font-bold text-sm transition-all active:scale-95 flex items-center justify-center gap-2 border border-slate-200/80 dark:border-slate-700"
          >
            <RefreshCw size={15} />
            <span>{t('btn_try_again')}</span>
          </button>
        </div>

      </div>
    </div>
  );
}

