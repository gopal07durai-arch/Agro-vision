import { useEffect, useState } from 'react';
import { History, RefreshCw, Leaf } from 'lucide-react';
import { getSessionHistory } from '../../services/supabaseService';
import type { PredictionHistoryEntry } from '../../types';
import { HistoryCard } from './HistoryCard';
import { useLanguage } from '../../i18n';

interface HistoryPageProps {
  sessionId: string;
  onBack: () => void;
}

function HistorySkeleton() {
  return (
    <div className="space-y-3">
      {[0, 1, 2].map(i => (
        <div
          key={i}
          className="bg-white/80 dark:bg-slate-900/80 rounded-3xl p-5 border border-slate-200/80 dark:border-slate-800 flex items-start gap-4 animate-pulse shadow-soft-sm"
          style={{ animationDelay: `${i * 80}ms` }}
        >
          <div className="w-14 h-14 rounded-2xl bg-slate-200 dark:bg-slate-800 flex-shrink-0" />
          <div className="flex-1 space-y-2.5">
            <div className="h-4 rounded-xl bg-slate-200 dark:bg-slate-800 w-1/3" />
            <div className="h-3 rounded-xl bg-slate-200 dark:bg-slate-800 w-1/2" />
            <div className="h-2 rounded-full bg-slate-200 dark:bg-slate-800 w-full" />
          </div>
        </div>
      ))}
    </div>
  );
}

function EmptyState({ onBack }: { onBack: () => void }) {
  const { t } = useLanguage();
  return (
    <div className="bg-white/80 dark:bg-slate-900/80 backdrop-blur-xl rounded-3xl border border-slate-200/80 dark:border-slate-800 p-10 text-center flex flex-col items-center justify-center shadow-soft-xl animate-fade-in-up">
      <div className="w-20 h-20 bg-emerald-50 dark:bg-emerald-950/60 border border-emerald-200 dark:border-emerald-800 rounded-3xl flex items-center justify-center mb-5 text-emerald-500 shadow-soft-sm">
        <Leaf size={36} />
      </div>
      <h3 className="text-xl font-bold font-display text-slate-900 dark:text-white mb-2">
        {t('history_empty_title')}
      </h3>
      <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 mb-8 max-w-xs leading-relaxed font-medium">
        {t('history_empty_desc')}
      </p>
      <button
        type="button"
        onClick={onBack}
        className="h-12 px-6 bg-gradient-to-r from-emerald-600 to-green-600 hover:from-emerald-500 hover:to-green-500 text-white rounded-2xl font-bold text-xs sm:text-sm shadow-glow-green active:scale-95 transition-all flex items-center gap-2"
        id="history-scan-now-btn"
      >
        <Leaf size={16} />
        <span>{t('history_scan_now')}</span>
      </button>
    </div>
  );
}

export function HistoryPage({ sessionId, onBack }: HistoryPageProps) {
  const { t } = useLanguage();
  const [entries, setEntries] = useState<PredictionHistoryEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await getSessionHistory(sessionId, 50);
      setEntries(data);
    } catch {
      setError(t('history_failed_load'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, [sessionId]);

  const avgConfidence = entries.length > 0
    ? (entries.reduce((s, e) => s + (e.disease_confidence || e.crop_confidence || 0), 0) / entries.length).toFixed(0)
    : '0';

  return (
    <div className="relative z-10 pb-16 pt-6 sm:pt-8 px-4 sm:px-6 lg:px-8">
      <div className="max-w-3xl mx-auto space-y-6">

        {/* Page Header */}
        <div className="flex items-center justify-between gap-3 animate-fade-in">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 bg-gradient-to-br from-emerald-500 to-green-600 rounded-2xl flex items-center justify-center text-white shadow-glow-green flex-shrink-0">
              <History size={22} />
            </div>
            <div>
              <h2 className="text-xl sm:text-2xl font-black font-display text-slate-900 dark:text-white leading-tight">
                {t('history_title')}
              </h2>
              {!loading && entries.length > 0 && (
                <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">
                  {entries.length} {t('history_scans')}
                </p>
              )}
            </div>
          </div>

          {/* Refresh button */}
          <button
            type="button"
            onClick={load}
            disabled={loading}
            className="p-2.5 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 text-slate-600 dark:text-slate-300 hover:text-emerald-600 dark:hover:text-emerald-400 hover:border-emerald-300 dark:hover:border-emerald-700 transition-all shadow-soft-sm disabled:opacity-50 active:scale-95"
            aria-label="Refresh history"
            id="history-refresh-btn"
          >
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
          </button>
        </div>

        {/* Aggregate Stats Cards */}
        {!loading && entries.length > 0 && (
          <div className="grid grid-cols-3 gap-3 animate-fade-in-up">
            <div className="p-4 rounded-2xl bg-white/90 dark:bg-slate-900/90 border border-slate-200/80 dark:border-slate-800 text-center shadow-soft-sm">
              <div className="text-2xl mb-1">🔬</div>
              <p className="text-lg sm:text-xl font-black font-display text-emerald-600 dark:text-emerald-400">
                {entries.length}
              </p>
              <p className="text-[11px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-wider">{t('history_scans')}</p>
            </div>

            <div className="p-4 rounded-2xl bg-white/90 dark:bg-slate-900/90 border border-slate-200/80 dark:border-slate-800 text-center shadow-soft-sm">
              <div className="text-2xl mb-1">📊</div>
              <p className="text-lg sm:text-xl font-black font-display text-blue-600 dark:text-blue-400">
                {avgConfidence}%
              </p>
              <p className="text-[11px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-wider">{t('history_avg_confidence')}</p>
            </div>

            <div className="p-4 rounded-2xl bg-white/90 dark:bg-slate-900/90 border border-slate-200/80 dark:border-slate-800 text-center shadow-soft-sm">
              <div className="text-2xl mb-1">⚠️</div>
              <p className="text-lg sm:text-xl font-black font-display text-amber-600 dark:text-amber-400">
                {entries.filter(e => e.disease_name.toLowerCase() !== 'healthy').length}
              </p>
              <p className="text-[11px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-wider">{t('history_diseases_found')}</p>
            </div>
          </div>
        )}

        {/* Content States */}
        {loading && <HistorySkeleton />}

        {!loading && error && (
          <div className="p-6 rounded-3xl bg-rose-50/90 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-800 text-center animate-fade-in">
            <p className="text-2xl mb-2">⚠️</p>
            <p className="text-sm font-bold text-rose-800 dark:text-rose-200 mb-1">{t('error')}</p>
            <p className="text-xs text-rose-600 dark:text-rose-400 mb-4">{error}</p>
            <button
              type="button"
              onClick={load}
              className="px-5 py-2.5 bg-rose-600 text-white rounded-xl text-xs font-bold shadow-soft-sm"
              id="history-retry-btn"
            >
              {t('retry')}
            </button>
          </div>
        )}

        {!loading && !error && entries.length === 0 && <EmptyState onBack={onBack} />}

        {!loading && !error && entries.length > 0 && (
          <div className="space-y-3">
            {entries.map((entry, i) => (
              <HistoryCard key={entry.id} entry={entry} index={i} />
            ))}

            <p className="text-center text-xs text-slate-400 dark:text-slate-500 pt-4 font-medium">
              {t('history_showing_last')}
            </p>
          </div>
        )}

      </div>
    </div>
  );
}
