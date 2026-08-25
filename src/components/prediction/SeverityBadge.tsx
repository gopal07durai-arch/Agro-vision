import type { SeverityLevel } from '../../types';
import { SEVERITY_COLORS, SEVERITY_DOT } from '../../utils/diseaseUtils';
import { useLanguage } from '../../i18n';

interface SeverityBadgeProps {
  severity: SeverityLevel;
  size?: 'sm' | 'md' | 'lg';
}

const SIZE_CLASSES = {
  sm: 'text-xs px-2 py-0.5',
  md: 'text-sm px-3 py-1',
  lg: 'text-base px-4 py-1.5',
};

export function SeverityBadge({ severity, size = 'md' }: SeverityBadgeProps) {
  const { translateSeverity } = useLanguage();
  return (
    <span className={`
      inline-flex items-center gap-1.5 rounded-full font-semibold
      ${SIZE_CLASSES[size]}
      ${SEVERITY_COLORS[severity]}
    `}>
      <span className={`w-1.5 h-1.5 rounded-full ${SEVERITY_DOT[severity]} animate-pulse`} />
      {translateSeverity(severity)}
    </span>
  );
}
