import { Card } from '@components/common/Card';
import { formatCurrency, formatPercentage, getGainLossColor } from '@utils/formatters';
import type { Investment } from '@types/index';
import { ArrowTrendingUpIcon, ArrowTrendingDownIcon, MinusIcon } from '@heroicons/react/24/solid';

interface InvestmentCardProps {
  investment: Investment;
  onClick?: () => void;
}

export function InvestmentCard({ investment, onClick }: InvestmentCardProps) {
  const {
    symbol,
    name,
    quantity,
    purchase_price,
    current_price,
    current_value,
    gain_loss,
    gain_loss_percent,
    performance_status,
    currency,
  } = investment;

  const getStatusIcon = () => {
    switch (performance_status) {
      case 'profitable':
        return <ArrowTrendingUpIcon className="w-5 h-5 text-[#10b981]" />;
      case 'losing':
        return <ArrowTrendingDownIcon className="w-5 h-5 text-[#ef4444]" />;
      default:
        return <MinusIcon className="w-5 h-5 text-gray-400" />;
    }
  };

  const getStatusBadgeColor = () => {
    switch (performance_status) {
      case 'profitable':
        return 'bg-[#10b981]/10 text-[#10b981] border-[#10b981]/30';
      case 'losing':
        return 'bg-[#ef4444]/10 text-[#ef4444] border-[#ef4444]/30';
      default:
        return 'bg-gray-500/10 text-gray-400 border-gray-500/30';
    }
  };

  return (
    <Card hover padding="md" className="relative" onClick={onClick}>
      <div className="flex items-start justify-between mb-4">
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-1">
            <h3 className="text-xl font-bold text-white">{symbol}</h3>
            {getStatusIcon()}
          </div>
          <p className="text-sm text-gray-400 truncate">{name}</p>
        </div>

        <div
          className={`px-2.5 py-1 rounded-full text-xs font-medium border ${getStatusBadgeColor()}`}
        >
          {performance_status === 'profitable' && 'Profitable'}
          {performance_status === 'losing' && 'Losing'}
          {performance_status === 'neutral' && 'Neutral'}
        </div>
      </div>

      <div className="space-y-3">
        <div className="flex justify-between items-center">
          <span className="text-sm text-gray-400">Quantity</span>
          <span className="text-sm font-medium text-white">{quantity.toFixed(2)}</span>
        </div>

        <div className="flex justify-between items-center">
          <span className="text-sm text-gray-400">Purchase Price</span>
          <span className="text-sm font-medium text-white">
            {formatCurrency(purchase_price, currency)}
          </span>
        </div>

        {current_price !== null && (
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-400">Current Price</span>
            <span className={`text-sm font-medium ${getGainLossColor(gain_loss)}`}>
              {formatCurrency(current_price, currency)}
            </span>
          </div>
        )}

        {current_value !== null && (
          <div className="flex justify-between items-center pt-2 border-t border-[#1f2544]">
            <span className="text-sm font-medium text-gray-300">Current Value</span>
            <span className="text-base font-bold text-white">
              {formatCurrency(current_value, currency)}
            </span>
          </div>
        )}

        {gain_loss !== null && gain_loss_percent !== null && (
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-400">Gain/Loss</span>
            <div className="text-right">
              <div className={`text-sm font-bold ${getGainLossColor(gain_loss)}`}>
                {formatCurrency(gain_loss, currency)}
              </div>
              <div className={`text-xs ${getGainLossColor(gain_loss)}`}>
                {formatPercentage(gain_loss_percent)}
              </div>
            </div>
          </div>
        )}
      </div>
    </Card>
  );
}
