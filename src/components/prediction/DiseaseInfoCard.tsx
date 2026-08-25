import { useState } from 'react';
import { Loader2, Info, AlertTriangle, Bug, FlaskConical, ShieldCheck, Sparkles } from 'lucide-react';
import type { DiseaseInfo } from '../../types';
import { useLanguage } from '../../i18n';
import type { TranslationKey } from '../../i18n/types';

interface DiseaseInfoCardProps {
  diseaseInfo: DiseaseInfo | null;
  isLoading: boolean;
  crop: string;
  disease: string;
}

type Tab = 'overview' | 'symptoms' | 'cause' | 'treatment' | 'prevention';

const TABS: Array<{ key: Tab; labelKey: TranslationKey; icon: React.ElementType }> = [
  { key: 'overview',   labelKey: 'disease_overview',            icon: Info },
  { key: 'symptoms',   labelKey: 'symptoms',                    icon: AlertTriangle },
  { key: 'cause',      labelKey: 'cause',                       icon: Bug },
  { key: 'treatment',  labelKey: 'treatment_recommendations',   icon: FlaskConical },
  { key: 'prevention', labelKey: 'preventive_measures',         icon: ShieldCheck },
];

function BulletList({ items, variant = 'emerald' }: { items: string[]; variant?: 'emerald' | 'rose' | 'amber' | 'blue' | 'purple' }) {
  const dotStyles = {
    emerald: 'bg-emerald-500 text-white',
    rose: 'bg-rose-500 text-white',
    amber: 'bg-amber-500 text-white',
    blue: 'bg-blue-500 text-white',
    purple: 'bg-purple-500 text-white',
  };

  return (
    <ul className="space-y-3">
      {items.map((item, idx) => (
        <li key={idx} className="flex items-start gap-3 text-xs sm:text-sm text-slate-700 dark:text-slate-300">
          <span className={`w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-bold flex-shrink-0 mt-0.5 shadow-soft-xs ${dotStyles[variant]}`}>
            {idx + 1}
          </span>
          <span className="leading-relaxed font-medium">{item}</span>
        </li>
      ))}
    </ul>
  );
}

export function DiseaseInfoCard({ diseaseInfo, isLoading, crop, disease }: DiseaseInfoCardProps) {
  const { t, translateCrop, translateDisease } = useLanguage();
  const [activeTab, setActiveTab] = useState<Tab>('overview');

  if (isLoading) {
    return (
      <div className="bg-white/90 dark:bg-slate-900/90 backdrop-blur-xl rounded-3xl border border-slate-200/90 dark:border-slate-800 p-8 flex items-center justify-center gap-3 animate-pulse shadow-soft-sm">
        <Loader2 size={24} className="animate-spin text-emerald-500" />
        <p className="text-slate-500 dark:text-slate-400 text-xs sm:text-sm font-bold">{t('loading')}...</p>
      </div>
    );
  }

  if (!diseaseInfo) return null;

  const translatedCrop = translateCrop(crop);
  const translatedDisease = translateDisease(disease);

  return (
    <div className="bg-white/90 dark:bg-slate-900/90 backdrop-blur-xl rounded-3xl border border-slate-200/90 dark:border-slate-800 shadow-soft-xl overflow-hidden animate-fade-in-up">
      
      {/* Header Bar */}
      <div className="p-6 sm:p-8 pb-4 border-b border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-950/30">
        <div className="flex items-center justify-between gap-3 mb-4">
          <div className="flex items-center gap-2.5">
            <div className="w-9 h-9 rounded-2xl bg-emerald-50 dark:bg-emerald-950/60 border border-emerald-200 dark:border-emerald-800 flex items-center justify-center text-emerald-600 dark:text-emerald-400">
              <Sparkles size={18} />
            </div>
            <div>
              <h3 className="text-base sm:text-lg font-black font-display text-slate-900 dark:text-white leading-tight">
                {t('disease_overview')}
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">
                {translatedCrop} • {translatedDisease}
              </p>
            </div>
          </div>
        </div>

        {/* Tab Navigation Pill Row */}
        <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-thin scrollbar-thumb-slate-300 dark:scrollbar-thumb-slate-700 -mx-2 px-2 pt-1">
          {TABS.map(({ key, labelKey, icon: Icon }) => {
            const isActive = activeTab === key;
            return (
              <button
                key={key}
                type="button"
                onClick={() => setActiveTab(key)}
                className={`
                  flex-shrink-0 min-h-[42px] flex items-center gap-2 px-4 py-2.5 rounded-2xl text-xs font-bold transition-all whitespace-nowrap active:scale-95
                  ${isActive
                    ? 'bg-gradient-to-r from-emerald-600 to-green-600 text-white shadow-glow-green scale-100'
                    : 'bg-white dark:bg-slate-800/90 text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white hover:bg-slate-50 dark:hover:bg-slate-800 border border-slate-200/80 dark:border-slate-700/80 shadow-soft-xs'
                  }
                `}
              >
                <Icon size={15} className={`flex-shrink-0 ${isActive ? 'text-white' : 'text-emerald-500'}`} />
                <span>{t(labelKey)}</span>
              </button>
            );
          })}
        </div>
      </div>


      {/* Tab Panels */}
      <div className="p-6 sm:p-8">
        
        {/* Overview Tab */}
        {activeTab === 'overview' && (
          <div className="space-y-4 animate-fade-in">
            <div className="p-5 rounded-2xl bg-slate-50 dark:bg-slate-800/50 border border-slate-200/80 dark:border-slate-700/80 text-xs sm:text-sm text-slate-700 dark:text-slate-300 leading-relaxed font-medium">
              {diseaseInfo.overview}
            </div>

            {diseaseInfo.farmerFriendlyExplanation && (
              <div className="p-5 rounded-2xl bg-emerald-50/80 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800/80">
                <p className="text-xs font-bold text-emerald-900 dark:text-emerald-300 uppercase tracking-wider mb-2 flex items-center gap-1.5">
                  <Sparkles size={14} className="text-emerald-500" />
                  <span>{t('farmer_explanation')}</span>
                </p>
                <p className="text-xs sm:text-sm text-emerald-950/90 dark:text-emerald-200 leading-relaxed font-medium">
                  {diseaseInfo.farmerFriendlyExplanation}
                </p>
              </div>
            )}
          </div>
        )}

        {/* Symptoms Tab */}
        {activeTab === 'symptoms' && (
          <div className="animate-fade-in">
            <BulletList items={diseaseInfo.symptoms ?? []} variant="rose" />
          </div>
        )}

        {/* Cause & Spread Tab */}
        {activeTab === 'cause' && (
          <div className="space-y-4 animate-fade-in">
            <div className="p-5 rounded-2xl bg-slate-50 dark:bg-slate-800/50 border border-slate-200/80 dark:border-slate-700/80">
              <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500 mb-1.5">
                {t('cause')}
              </h4>
              <p className="text-xs sm:text-sm text-slate-800 dark:text-slate-200 leading-relaxed font-medium">
                {diseaseInfo.cause}
              </p>
            </div>

            <div className="p-5 rounded-2xl bg-slate-50 dark:bg-slate-800/50 border border-slate-200/80 dark:border-slate-700/80">
              <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500 mb-1.5">
                {t('spread_method')}
              </h4>
              <p className="text-xs sm:text-sm text-slate-800 dark:text-slate-200 leading-relaxed font-medium">
                {diseaseInfo.spreadMethod}
              </p>
            </div>
          </div>
        )}

        {/* Treatment Recommendations Tab */}
        {activeTab === 'treatment' && (
          <div className="space-y-6 animate-fade-in">
            {diseaseInfo.organicControl && diseaseInfo.organicControl.length > 0 && (
              <div>
                <h4 className="text-xs font-bold uppercase tracking-wider text-emerald-600 dark:text-emerald-400 mb-3">
                  🌿 {t('organic_control')}
                </h4>
                <BulletList items={diseaseInfo.organicControl} variant="emerald" />
              </div>
            )}

            {diseaseInfo.chemicalControl && diseaseInfo.chemicalControl.length > 0 && (
              <div className="pt-4 border-t border-slate-100 dark:border-slate-800">
                <h4 className="text-xs font-bold uppercase tracking-wider text-purple-600 dark:text-purple-400 mb-3">
                  🧪 {t('chemical_control')}
                </h4>
                <BulletList items={diseaseInfo.chemicalControl} variant="purple" />
              </div>
            )}
          </div>
        )}

        {/* Preventive Measures Tab */}
        {activeTab === 'prevention' && (
          <div className="space-y-4 animate-fade-in">
            {diseaseInfo.preventiveMeasures && diseaseInfo.preventiveMeasures.length > 0 && (
              <BulletList items={diseaseInfo.preventiveMeasures} variant="blue" />
            )}
          </div>
        )}

      </div>
    </div>
  );
}

