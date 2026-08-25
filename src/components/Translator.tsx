import { useState, useRef, useEffect } from 'react';
import { Globe, Check } from 'lucide-react';
import { useLanguage } from '../i18n/useLanguage';
import { SUPPORTED_LANGUAGES, type LanguageCode } from '../i18n/types';

export function Translator() {
  const { language, setLanguage, t } = useLanguage();
  const [isOpen, setIsOpen] = useState(false);

  const dropdownRef = useRef<HTMLDivElement>(null);

  const currentLangInfo = SUPPORTED_LANGUAGES.find((l) => l.code === language) || SUPPORTED_LANGUAGES[0];

  const handleLanguageSelect = (code: LanguageCode) => {
    setLanguage(code);
    setIsOpen(false);
  };

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className="relative" ref={dropdownRef}>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-800 dark:text-slate-100 border border-slate-200/80 dark:border-slate-700/80 transition-all font-medium text-xs sm:text-sm shadow-soft-sm active:scale-95"
        title={`Language: ${currentLangInfo.nativeName}`}
        aria-label="Change Language"
        id="header-translator-btn"
      >
        <Globe size={16} className="text-emerald-500 flex-shrink-0" />
        <span className="flex-shrink-0">{currentLangInfo.flag}</span>
        <span className="font-bold">{currentLangInfo.nativeName}</span>
      </button>

      {isOpen && (
        <div className="absolute right-0 mt-2 w-52 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-200 rounded-2xl shadow-soft-xl z-50 overflow-hidden border border-slate-200 dark:border-slate-800 animate-fade-in-up">
          <div className="px-3.5 py-2.5 bg-slate-50 dark:bg-slate-800/80 border-b border-slate-100 dark:border-slate-800">
            <p className="text-[11px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              {t('select_language')}
            </p>
          </div>


          <div className="max-h-60 overflow-y-auto scrollbar-hide py-1">
            {SUPPORTED_LANGUAGES.map((lang) => {
              const isSelected = language === lang.code;
              return (
                <button
                  key={lang.code}
                  onClick={() => handleLanguageSelect(lang.code)}
                  className={`w-full flex items-center justify-between px-4 py-2.5 text-xs sm:text-sm transition-all ${
                    isSelected
                      ? 'bg-green-50 dark:bg-green-900/30 text-green-700 dark:text-green-300 font-bold'
                      : 'text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-800/50'
                  }`}
                >
                  <div className="flex items-center gap-2.5">
                    <span className="text-base">{lang.flag}</span>
                    <div className="text-left">
                      <p className="leading-none font-medium">{lang.nativeName}</p>
                      <p className="text-[10px] text-gray-400 dark:text-gray-500 mt-0.5">{lang.name}</p>
                    </div>
                  </div>
                  {isSelected && <Check size={16} className="text-green-600 dark:text-green-400" />}
                </button>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
