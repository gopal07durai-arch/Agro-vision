import { useState } from 'react';
import { Sprout, Moon, Sun, ChevronLeft, History, Wifi, WifiOff, Menu, X, Info, Camera, Home } from 'lucide-react';
import { Translator } from '../Translator';
import { useLanguage } from '../../i18n';

interface HeaderProps {
  darkMode: boolean;
  onToggleDarkMode: () => void;
  showBack?: boolean;
  onBack?: () => void;
  onHistory?: () => void;
  onHome?: () => void;
  onScan?: () => void;
  onAbout?: () => void;
  currentView?: string;
  subtitle?: string;
  backendOnline?: boolean;
}

export function Header({
  darkMode,
  onToggleDarkMode,
  showBack,
  onBack,
  onHistory,
  onHome,
  onScan,
  onAbout,
  currentView,
  subtitle,
  backendOnline,
}: HeaderProps) {
  const { t } = useLanguage();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const handleNav = (action?: () => void) => {
    setMobileMenuOpen(false);
    if (action) action();
  };

  return (
    <header className="sticky top-0 z-40 bg-white/85 dark:bg-slate-900/85 backdrop-blur-xl border-b border-slate-200/80 dark:border-slate-800 transition-colors shadow-soft-sm">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16 gap-3">

          {/* Left: Brand Logo & Title */}
          <div className="flex items-center gap-3 min-w-0">
            {showBack && (
              <button
                type="button"
                onClick={onBack}
                className="w-10 h-10 flex items-center justify-center rounded-2xl bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-200 border border-slate-200/80 dark:border-slate-700/80 shadow-soft-xs active:scale-95 transition-all flex-shrink-0"
                aria-label={t('back')}
              >
                <ChevronLeft size={20} />
              </button>
            )}


            <button
              type="button"
              onClick={onHome}
              className="flex items-center gap-2.5 text-left group transition-transform active:scale-95"
            >
              <div className="w-10 h-10 rounded-2xl bg-gradient-to-br from-emerald-500 to-green-600 flex items-center justify-center text-white shadow-glow-green flex-shrink-0 group-hover:rotate-6 transition-transform">
                <Sprout size={22} />
              </div>

              <div className="min-w-0">
                <div className="flex items-center gap-1.5">
                  <span className="text-base sm:text-lg font-black font-display tracking-tight text-slate-900 dark:text-white leading-none">
                    AgroVision <span className="text-emerald-600 dark:text-emerald-400">AI</span>
                  </span>
                </div>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 font-medium truncate hidden sm:block mt-0.5">
                  {subtitle ?? 'Smart Crop Disease Detection Platform'}
                </p>
              </div>
            </button>
          </div>

          {/* Center: Desktop Navigation Links */}
          <nav className="hidden md:flex items-center gap-1 bg-slate-100/80 dark:bg-slate-800/80 p-1 rounded-2xl border border-slate-200/60 dark:border-slate-700/60">
            <button
              type="button"
              onClick={onHome}
              className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all ${
                currentView === 'upload' && !showBack
                  ? 'bg-white dark:bg-slate-900 text-emerald-600 dark:text-emerald-400 shadow-soft-sm'
                  : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
              }`}
            >
              <Home size={14} className="flex-shrink-0" />
              <span className="whitespace-nowrap">{t('nav_home')}</span>
            </button>

            <button
              type="button"
              onClick={onScan}
              className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all ${
                currentView === 'prediction' || currentView === 'analyzing'
                  ? 'bg-white dark:bg-slate-900 text-emerald-600 dark:text-emerald-400 shadow-soft-sm'
                  : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
              }`}
            >
              <Camera size={14} className="flex-shrink-0" />
              <span className="whitespace-nowrap">{t('nav_scan')}</span>
            </button>

            <button
              type="button"
              onClick={onHistory}
              className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all ${
                currentView === 'history'
                  ? 'bg-white dark:bg-slate-900 text-emerald-600 dark:text-emerald-400 shadow-soft-sm'
                  : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
              }`}
            >
              <History size={14} className="flex-shrink-0" />
              <span className="whitespace-nowrap">{t('nav_history')}</span>
            </button>

            <button
              type="button"
              onClick={onAbout}
              className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white transition-all"
            >
              <Info size={14} className="flex-shrink-0" />
              <span className="whitespace-nowrap">{t('nav_about')}</span>
            </button>
          </nav>

          {/* Right: Controls (Status, Language, Theme, Mobile Hamburger) */}
          <div className="flex items-center gap-2 flex-shrink-0">
            {/* Live Backend Connection Indicator */}
            {typeof backendOnline === 'boolean' && (
              <div
                className={`hidden lg:flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold border transition-colors ${
                  backendOnline
                    ? 'bg-emerald-50 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-300 border-emerald-200 dark:border-emerald-800'
                    : 'bg-rose-50 dark:bg-rose-950/60 text-rose-700 dark:text-rose-300 border-rose-200 dark:border-rose-800'
                }`}
                title={backendOnline ? t('online') : t('offline')}
              >
                {backendOnline ? (
                  <>
                    <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                    <span>{t('online')}</span>
                  </>
                ) : (
                  <>
                    <span className="w-2 h-2 rounded-full bg-rose-500" />
                    <span>{t('offline')}</span>
                  </>
                )}
              </div>
            )}

            {/* Language Selector */}
            <div className="flex-shrink-0">
              <Translator />
            </div>

            {/* Dark Mode Toggle */}
            <button
              type="button"
              onClick={onToggleDarkMode}
              className="p-2.5 rounded-xl bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-200 border border-slate-200/80 dark:border-slate-700/80 transition-all active:scale-95 shadow-soft-sm"
              aria-label={darkMode ? t('light_mode') : t('dark_mode')}
              title={darkMode ? t('light_mode') : t('dark_mode')}
              id="header-dark-mode-btn"
            >
              {darkMode ? <Sun size={17} className="text-amber-400" /> : <Moon size={17} className="text-slate-700" />}
            </button>

            {/* Mobile Menu Button */}
            <button
              type="button"
              onClick={() => setMobileMenuOpen(o => !o)}
              className="md:hidden p-2.5 rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-200 border border-slate-200/80 dark:border-slate-700/80 transition-colors"
              aria-label="Toggle navigation menu"
            >
              {mobileMenuOpen ? <X size={18} /> : <Menu size={18} />}
            </button>
          </div>

        </div>
      </div>

      {/* Mobile Navigation Drawer */}
      {mobileMenuOpen && (
        <div className="md:hidden border-t border-slate-200 dark:border-slate-800 bg-white/95 dark:bg-slate-900/95 backdrop-blur-xl px-4 py-4 space-y-2 animate-fade-in">
          <button
            type="button"
            onClick={() => handleNav(onHome)}
            className="w-full min-h-[44px] flex items-center gap-3 p-3 rounded-xl text-left text-xs font-bold text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          >
            <Home size={16} className="text-emerald-500 flex-shrink-0" />
            <span className="break-words leading-relaxed">{t('nav_home')}</span>
          </button>

          <button
            type="button"
            onClick={() => handleNav(onScan)}
            className="w-full min-h-[44px] flex items-center gap-3 p-3 rounded-xl text-left text-xs font-bold text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          >
            <Camera size={16} className="text-emerald-500 flex-shrink-0" />
            <span className="break-words leading-relaxed">{t('nav_scan')}</span>
          </button>

          <button
            type="button"
            onClick={() => handleNav(onHistory)}
            className="w-full min-h-[44px] flex items-center gap-3 p-3 rounded-xl text-left text-xs font-bold text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          >
            <History size={16} className="text-emerald-500 flex-shrink-0" />
            <span className="break-words leading-relaxed">{t('nav_history')}</span>
          </button>

          <button
            type="button"
            onClick={() => handleNav(onAbout)}
            className="w-full min-h-[44px] flex items-center gap-3 p-3 rounded-xl text-left text-xs font-bold text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          >
            <Info size={16} className="text-emerald-500 flex-shrink-0" />
            <span className="break-words leading-relaxed">{t('about_agrovision')}</span>
          </button>
        </div>
      )}
    </header>
  );
}

