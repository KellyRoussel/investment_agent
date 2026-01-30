import { Card } from '@components/common/Card';
import { ReactNode } from 'react';

interface PortfolioMetricsCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon?: ReactNode;
  trend?: 'up' | 'down' | 'neutral';
  trendValue?: string;
}

export function PortfolioMetricsCard({
  title,
  value,
  subtitle,
  icon,
  trend,
  trendValue,
}: PortfolioMetricsCardProps) {
  const getTrendColor = () => {
    switch (trend) {
      case 'up':
        return 'text-[#10b981]';
      case 'down':
        return 'text-[#ef4444]';
      default:
        return 'text-gray-400';
    }
  };

  return (
    <Card hover={false}>
      <div className="flex items-start justify-between gap-2 mb-3">
        <div className="flex-1 min-w-0">
          <p className="text-sm text-gray-400 mb-1 truncate">{title}</p>
          <h3 className="text-2xl sm:text-3xl font-bold text-white truncate">{value}</h3>
        </div>
        {icon && <div className="text-[#22d3ee] flex-shrink-0">{icon}</div>}
      </div>

      {(subtitle || trendValue) && (
        <div className="flex items-center justify-between gap-2 mt-3 pt-3 border-t border-[#1f2544]">
          {subtitle && <p className="text-xs text-gray-400 truncate flex-1 min-w-0">{subtitle}</p>}
          {trendValue && (
            <p className={`text-sm font-medium flex-shrink-0 ${getTrendColor()}`}>{trendValue}</p>
          )}
        </div>
      )}
    </Card>
  );
}
