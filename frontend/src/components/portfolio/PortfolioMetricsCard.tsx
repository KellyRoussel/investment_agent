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
      <div className="flex items-start justify-between mb-3">
        <div className="flex-1">
          <p className="text-sm text-gray-400 mb-1">{title}</p>
          <h3 className="text-3xl font-bold text-white">{value}</h3>
        </div>
        {icon && <div className="text-[#22d3ee]">{icon}</div>}
      </div>

      {(subtitle || trendValue) && (
        <div className="flex items-center justify-between mt-3 pt-3 border-t border-[#1f2544]">
          {subtitle && <p className="text-xs text-gray-400">{subtitle}</p>}
          {trendValue && (
            <p className={`text-sm font-medium ${getTrendColor()}`}>{trendValue}</p>
          )}
        </div>
      )}
    </Card>
  );
}
