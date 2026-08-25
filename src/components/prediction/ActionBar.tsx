import { MessageSquare, RotateCcw, Download, Star, Sparkles } from 'lucide-react';
import { useState } from 'react';
import { useLanguage } from '../../i18n';

interface ActionBarProps {
  onChat: () => void;
  onReset: () => void;
  onDownload: () => void;
  onRate: (rating: number) => void;
}

export function ActionBar({ onChat, onReset, onDownload, onRate }: ActionBarProps) {
  const { t } = useLanguage();
  const [rated, setRated] = useState(0);
  const [hovered, setHovered] = useState(0);

  const handleRate = (r: number) => {
    setRated(r);
    onRate(r);
  };

  return (
    <div className="sticky bottom-0 z-40 bg-white/95 dark:bg-slate-900/95 backdrop-blur-xl border-t border-slate-200/90 dark:border-slate-800 shadow-[0_-10px_25px_-5px_rgba(0,0,0,0.08)] dark:shadow-[0_-10px_25px_-5px_rgba(0,0,0,0.5)]">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 py-3.5">

        {/* Star Rating Feedback Row */}
        <div className="flex items-center justify-center gap-2 mb-2.5">
          <span className="text-xs font-bold text-slate-500 dark:text-slate-400 flex items-center gap-1">
            <Sparkles size={12} className="text-amber-500" />
            <span>{t('rate_prompt')}:</span>
          </span>
          <div className="flex items-center gap-1">
            {[1, 2, 3, 4, 5].map(star => (
              <button
                key={star}
                type="button"
                onClick={() => handleRate(star)}
                onMouseEnter={() => setHovered(star)}
                onMouseLeave={() => setHovered(0)}
                className="p-1 transition-transform hover:scale-125 active:scale-95"
                aria-label={`Rate ${star} stars`}
              >
                <Star
                  size={16}
                  className={`transition-colors ${star <= (hovered || rated)
                    ? 'text-amber-400 fill-amber-400'
                    : 'text-slate-300 dark:text-slate-600'
                  }`}
                />
              </button>
            ))}
          </div>

          {rated > 0 && (
            <span className="text-xs text-emerald-600 dark:text-emerald-400 font-bold ml-1.5 animate-fade-in bg-emerald-50 dark:bg-emerald-950/60 px-2.5 py-0.5 rounded-full border border-emerald-200 dark:border-emerald-800">
              ✓ {t('rating_thank_you')}
            </span>
          )}
        </div>

        {/* 3 Main Action Buttons with Equal Heights & High Contrast */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5 sm:gap-3">
          
          {/* 1. Ask AI Assistant */}
          <button
            type="button"
            onClick={onChat}
            className="min-h-[46px] py-2.5 flex items-center justify-center gap-2 px-4 bg-gradient-to-r from-emerald-600 to-green-600 hover:from-emerald-500 hover:to-green-500 text-white rounded-2xl font-bold text-xs sm:text-sm shadow-glow-green active:scale-95 transition-all"
          >
            <MessageSquare size={16} className="flex-shrink-0" />
            <span className="break-words text-center">{t('start_chat')}</span>
          </button>

          {/* 2. Download Report */}
          <button
            type="button"
            onClick={onDownload}
            className="min-h-[46px] py-2.5 flex items-center justify-center gap-2 px-4 bg-blue-600 hover:bg-blue-500 text-white rounded-2xl font-bold text-xs sm:text-sm shadow-soft-sm active:scale-95 transition-all"
          >
            <Download size={16} className="flex-shrink-0" />
            <span className="break-words text-center">{t('download_report')}</span>
          </button>

          {/* 3. Scan Another Leaf */}
          <button
            type="button"
            onClick={onReset}
            className="min-h-[46px] py-2.5 flex items-center justify-center gap-2 px-4 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-800 dark:text-slate-200 rounded-2xl font-bold text-xs sm:text-sm border border-slate-200/80 dark:border-slate-700 shadow-soft-xs active:scale-95 transition-all"
          >
            <RotateCcw size={15} className="flex-shrink-0" />
            <span className="break-words text-center">{t('scan_another')}</span>
          </button>

        </div>
      </div>
    </div>
  );
}



