import { useEffect, useState } from 'react';
import { useLanguage } from '../../i18n';

interface ConfidenceIndicatorProps {
  value?: number;   // 0–100
  size?: number;
  label?: string;
}

export function ConfidenceIndicator({ value, size = 100, label }: ConfidenceIndicatorProps) {
  const { t } = useLanguage();
  const [animated, setAnimated] = useState(0);

  const hasValidValue = typeof value === 'number' && !isNaN(value) && value > 0;

  useEffect(() => {
    if (hasValidValue) {
      const timer = setTimeout(() => setAnimated(value), 150);
      return () => clearTimeout(timer);
    }
  }, [value, hasValidValue]);

  if (!hasValidValue) {
    return (
      <div className="flex flex-col items-center justify-center p-3 rounded-2xl bg-slate-100 dark:bg-slate-800/80 text-center w-full min-h-[90px]">
        <span className="text-xs font-semibold text-slate-500 dark:text-slate-400">
          {t('confidence_unavailable')}
        </span>
      </div>
    );
  }

  const strokeWidth = 8;
  const radius = (size - strokeWidth * 2) / 2;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference * (1 - animated / 100);

  const color =
    value >= 80 ? '#10b981' :
      value >= 60 ? '#f59e0b' :
        '#ef4444';

  const trackColor =
    value >= 80 ? 'rgba(16, 185, 129, 0.12)' :
      value >= 60 ? 'rgba(245, 158, 11, 0.12)' :
        'rgba(239, 68, 68, 0.12)';

  return (
    <div className="flex flex-col items-center justify-center">
      <div
        className="relative flex items-center justify-center"
        style={{ width: size, height: size }}
      >
        <svg width={size} height={size} className="-rotate-90">
          {/* Background Track */}
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            fill="none"
            stroke="currentColor"
            strokeWidth={strokeWidth}
            className="text-slate-100 dark:text-slate-800"
          />
          {/* Tinted Track */}
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            fill="none"
            stroke={trackColor}
            strokeWidth={strokeWidth}
          />
          {/* Progress Arc */}
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            fill="none"
            stroke={color}
            strokeWidth={strokeWidth}
            strokeLinecap="round"
            strokeDasharray={circumference}
            strokeDashoffset={strokeDashoffset}
            style={{
              transition: 'stroke-dashoffset 1.2s cubic-bezier(0.34, 1.56, 0.64, 1)',
            }}
          />
        </svg>

        {/* Clean Centered Percentage */}
        <div className="absolute inset-0 flex items-center justify-center">
          <span className="text-xl sm:text-2xl font-black font-display tracking-tight text-slate-900 dark:text-white">
            {Math.round(animated)}%
          </span>
        </div>
      </div>

      {/* Optional Sub-Label Outside Ring */}
      {label && (
        <span className="text-[11px] font-bold text-slate-500 dark:text-slate-400 mt-1.5 uppercase tracking-wider text-center">
          {label}
        </span>
      )}
    </div>
  );
}


