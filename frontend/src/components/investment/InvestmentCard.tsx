import { Card } from '@components/common/Card';
import { formatCurrency } from '@utils/formatters';
import type { Investment } from '@types/index';

interface InvestmentCardProps {
  investment: Investment;
  onClick?: () => void;
}

const THESIS_STATUS_CONFIG = {
  valid: { label: 'Valid', className: 'bg-[#10b981]/10 text-[#10b981] border-[#10b981]/30' },
  watch: { label: 'Watch', className: 'bg-[#f59e0b]/10 text-[#f59e0b] border-[#f59e0b]/30' },
  reconsider: { label: 'Reconsider', className: 'bg-[#ef4444]/10 text-[#ef4444] border-[#ef4444]/30' },
} as const;

export function InvestmentCard({ investment, onClick }: InvestmentCardProps) {
  const {
    symbol,
    name,
    quantity,
    purchase_price,
    currency,
    asset_type,
    sector,
    account_type,
    investment_thesis,
    thesis_status,
    alert_threshold_pct,
  } = investment;

  const thesisConfig = thesis_status ? THESIS_STATUS_CONFIG[thesis_status] : null;

  return (
    <Card hover padding="md" className="relative" onClick={onClick}>
      {/* Header */}
      <div className="flex items-start justify-between mb-4">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <h3 className="text-xl font-bold text-white">{symbol}</h3>
            {thesisConfig && (
              <span className={`px-2 py-0.5 rounded-full text-xs font-medium border ${thesisConfig.className}`}>
                {thesisConfig.label}
              </span>
            )}
          </div>
          <p className="text-sm text-gray-400 truncate">{name}</p>
        </div>

        <div className="flex flex-col items-end gap-1 flex-shrink-0 ml-2">
          <div className="px-2.5 py-1 rounded-full text-xs font-medium border bg-blue-500/10 text-blue-400 border-blue-500/30">
            {asset_type.toUpperCase()}
          </div>
          {account_type && (
            <div className="px-2.5 py-1 rounded-full text-xs font-medium border bg-[#a78bfa]/10 text-[#a78bfa] border-[#a78bfa]/30">
              {account_type}
            </div>
          )}
        </div>
      </div>

      {/* Metrics */}
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
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-400">Sector</span>
            <span className="text-sm font-medium text-gray-300">{sector}</span>
          </div>
        )}

        {alert_threshold_pct !== null && alert_threshold_pct !== undefined && (
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-400">Alert at</span>
            <span className="text-sm font-medium text-[#f59e0b]">
              {alert_threshold_pct > 0 ? '+' : ''}{alert_threshold_pct}%
            </span>
          </div>
        )}
      </div>

      {/* Investment Thesis */}
      {investment_thesis && (
        <div className="mt-3 pt-3 border-t border-[#1f2544]">
          <p className="text-xs text-gray-500 mb-1 font-medium uppercase tracking-wide">Thesis</p>
          <p className="text-xs text-gray-400 line-clamp-2">{investment_thesis}</p>
        </div>
      )}
    </Card>
  );
}
