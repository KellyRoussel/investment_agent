import { Card } from '@components/common/Card';
import { formatPercentage, getGainLossColor } from '@utils/formatters';
import { ArrowTrendingUpIcon, ArrowTrendingDownIcon } from '@heroicons/react/24/solid';

interface Performer {
  symbol: string;
  name: string;
  gain_loss_percent: number;
}

interface PerformersTableProps {
  title: string;
  performers: Performer[];
  type: 'top' | 'worst';
}

export function PerformersTable({ title, performers, type }: PerformersTableProps) {
  const Icon = type === 'top' ? ArrowTrendingUpIcon : ArrowTrendingDownIcon;
  const iconColor = type === 'top' ? 'text-[#10b981]' : 'text-[#ef4444]';

  if (!performers || performers.length === 0) {
    return (
      <Card>
        <h3 className="text-lg font-semibold text-white mb-4">{title}</h3>
        <div className="flex items-center justify-center py-8">
          <p className="text-gray-400">No data available</p>
        </div>
      </Card>
    );
  }

  return (
    <Card>
      <div className="flex items-center gap-2 mb-4">
        <Icon className={`w-5 h-5 ${iconColor}`} />
        <h3 className="text-lg font-semibold text-white">{title}</h3>
      </div>

      <div className="space-y-3">
        {performers.map((performer, index) => (
          <div
            key={performer.symbol}
            className="flex items-center justify-between p-3 bg-[#0a0e27] rounded-lg hover:bg-[#252b4a] transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div
                className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm ${
                  type === 'top'
                    ? 'bg-[#10b981]/10 text-[#10b981]'
                    : 'bg-[#ef4444]/10 text-[#ef4444]'
                }`}
              >
                {index + 1}
              </div>
              <div>
                <p className="text-white font-medium">{performer.symbol}</p>
                <p className="text-xs text-gray-400 truncate max-w-[200px]">{performer.name}</p>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <span
                className={`text-lg font-bold ${getGainLossColor(performer.gain_loss_percent)}`}
              >
                {formatPercentage(performer.gain_loss_percent)}
              </span>
              <Icon className={`w-4 h-4 ${iconColor}`} />
            </div>
          </div>
        ))}
      </div>
    </Card>
  );
}
