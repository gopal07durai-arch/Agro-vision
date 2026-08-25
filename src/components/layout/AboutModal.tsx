import { X, Sprout, ShieldCheck, Sparkles, Cpu, Globe2, FileText, CheckCircle2 } from 'lucide-react';
import { useLanguage } from '../../i18n';
import type { TranslationKey } from '../../i18n/types';

interface AboutModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const CROPS = [
  { nameKey: 'crop_Tomato',    icon: '🍅' },
  { nameKey: 'crop_Paddy',     icon: '🌾' },
  { nameKey: 'crop_Wheat',     icon: '🌾' },
  { nameKey: 'crop_Cotton',    icon: '🌿' },
  { nameKey: 'crop_Sugarcane', icon: '🎋' },
  { nameKey: 'crop_Groundnut', icon: '🥜' },
  { nameKey: 'crop_Sunflower', icon: '🌻' },
  { nameKey: 'crop_Turmeric',  icon: '🟡' },
  { nameKey: 'crop_Blackgram', icon: '🫘' },
  { nameKey: 'crop_Eggplant',  icon: '🍆' },
];

export function AboutModal({ isOpen, onClose }: AboutModalProps) {
  const { t } = useLanguage();

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6 animate-fade-in">
      {/* Backdrop */}
      <div
        onClick={onClose}
        className="absolute inset-0 bg-slate-950/70 backdrop-blur-md transition-opacity"
      />

      {/* Modal Container */}
      <div className="relative w-full max-w-2xl bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/80 dark:border-slate-800 shadow-soft-xl overflow-hidden z-10 max-h-[90vh] flex flex-col animate-fade-in-up">
        {/* Modal Header */}
        <div className="flex items-center justify-between p-6 pb-4 border-b border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-950/40">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-emerald-50 dark:bg-emerald-950/60 border border-emerald-200 dark:border-emerald-800 flex items-center justify-center text-emerald-600 dark:text-emerald-400">
              <Sprout size={22} />
            </div>
            <div>
              <h3 className="text-lg font-bold font-display text-slate-900 dark:text-white">
                AgroVision AI
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Smart Crop Disease Detection Platform
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={onClose}
            className="p-2 rounded-full text-slate-400 hover:text-slate-700 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
            aria-label={t('close')}
          >
            <X size={18} />
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-6 overflow-y-auto space-y-6 scrollbar-thin">
          {/* Mission */}
          <div className="p-5 rounded-2xl bg-emerald-50/60 dark:bg-emerald-950/40 border border-emerald-200/80 dark:border-emerald-800/80">
            <h4 className="text-xs font-bold uppercase tracking-wider text-emerald-900 dark:text-emerald-300 mb-1.5 flex items-center gap-1.5">
              <Sparkles size={14} className="text-emerald-500" />
              <span>{t('about_mission_title')}</span>
            </h4>
            <p className="text-xs sm:text-sm text-emerald-950/90 dark:text-emerald-200 leading-relaxed font-medium">
              {t('about_mission_desc')}
            </p>
          </div>

          {/* Architecture Details */}
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500 mb-3">
              {t('about_arch_title')}
            </h4>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="p-4 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200/80 dark:border-slate-700/80">
                <div className="flex items-center gap-2 text-xs font-bold text-slate-900 dark:text-white mb-1">
                  <Cpu size={15} className="text-emerald-500" />
                  <span>{t('about_stage1_title')}</span>
                </div>
                <p className="text-xs text-slate-600 dark:text-slate-400 leading-relaxed">
                  {t('about_stage1_desc')}
                </p>
              </div>

              <div className="p-4 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200/80 dark:border-slate-700/80">
                <div className="flex items-center gap-2 text-xs font-bold text-slate-900 dark:text-white mb-1">
                  <ShieldCheck size={15} className="text-purple-500" />
                  <span>{t('about_stage2_title')}</span>
                </div>
                <p className="text-xs text-slate-600 dark:text-slate-400 leading-relaxed">
                  {t('about_stage2_desc')}
                </p>
              </div>
            </div>
          </div>

          {/* Supported Crops */}
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500 mb-3">
              {t('about_crops_title')}
            </h4>
            <div className="flex flex-wrap gap-2">
              {CROPS.map(c => (
                <span
                  key={c.nameKey}
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-slate-50 dark:bg-slate-800/70 border border-slate-200/80 dark:border-slate-700/80 rounded-full text-xs font-medium text-slate-700 dark:text-slate-300"
                >
                  <span>{c.icon}</span>
                  <span>{t(c.nameKey as TranslationKey)}</span>
                </span>
              ))}
            </div>
          </div>

          {/* Core Features List */}
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500 mb-3">
              {t('about_features_title')}
            </h4>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs text-slate-600 dark:text-slate-400">
              <div className="flex items-center gap-2 p-2.5 rounded-xl bg-slate-50 dark:bg-slate-800/40">
                <CheckCircle2 size={15} className="text-emerald-500 flex-shrink-0" />
                <span>{t('about_feat_quality')}</span>
              </div>
              <div className="flex items-center gap-2 p-2.5 rounded-xl bg-slate-50 dark:bg-slate-800/40">
                <Globe2 size={15} className="text-blue-500 flex-shrink-0" />
                <span>{t('about_feat_lang')}</span>
              </div>
              <div className="flex items-center gap-2 p-2.5 rounded-xl bg-slate-50 dark:bg-slate-800/40">
                <FileText size={15} className="text-purple-500 flex-shrink-0" />
                <span>{t('about_feat_pdf')}</span>
              </div>
              <div className="flex items-center gap-2 p-2.5 rounded-xl bg-slate-50 dark:bg-slate-800/40">
                <Sparkles size={15} className="text-amber-500 flex-shrink-0" />
                <span>{t('about_feat_chat')}</span>
              </div>
            </div>
          </div>
        </div>


        {/* Modal Footer */}
        <div className="p-4 px-6 border-t border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-950/40 flex justify-end">
          <button
            type="button"
            onClick={onClose}
            className="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl font-bold text-xs shadow-glow-green transition-all active:scale-95"
          >
            {t('close')}
          </button>
        </div>
      </div>
    </div>
  );
}
