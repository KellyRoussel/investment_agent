import { Card } from '@components/common/Card';
import { formatCurrency } from '@utils/formatters';
import type { Investment } from '@types/index';

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
    currency,
    asset_type,
    sector,
  } = investment;

  return (
    <Card hover padding="md" className="relative" onClick={onClick}>
      <div className="flex items-start justify-between mb-4">
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-1">
            <h3 className="text-xl font-bold text-white">{symbol}</h3>
          </div>
          <p className="text-sm text-gray-400 truncate">{name}</p>
        </div>

        <div className="px-2.5 py-1 rounded-full text-xs font-medium border bg-blue-500/10 text-blue-400 border-blue-500/30">
          {asset_type.toUpperCase()}
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

        <div className="flex justify-between items-center">
          <span className="text-sm text-gray-400">Total Cost</span>
          <span className="text-sm font-medium text-white">
            {formatCurrency(purchase_price * quantity, currency)}
          </span>
        </div>

        {sector && (
          <div className="flex justify-between items-center pt-2 border-t border-[#1f2544]">
            <span className="text-sm text-gray-400">Sector</span>
            <span className="text-sm font-medium text-gray-300">{sector}</span>
          </div>
        )}
      </div>
    </Card>
  );
}
