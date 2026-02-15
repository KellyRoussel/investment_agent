import { useState, useEffect } from 'react';
import {
  CurrencyDollarIcon,
  ChartBarIcon,
  TrophyIcon,
  ScaleIcon,
  BanknotesIcon,
} from '@heroicons/react/24/outline';
import { LoadingSpinner } from '@components/common/LoadingSpinner';
import { PortfolioMetricsCard } from '@components/portfolio/PortfolioMetricsCard';
import { BreakdownChart } from '@components/portfolio/BreakdownChart';
import { PerformersTable } from '@components/portfolio/PerformersTable';
import { PortfolioHistoryChart } from '@components/portfolio/PortfolioHistoryChart';
import { portfolioService } from '@services/portfolioService';
import { formatCurrency, formatPercentage } from '@utils/formatters';
import type { PortfolioMetrics } from '@types/index';
import { useAuth } from '@hooks/useAuth';

export function Portfolio() {
  const { user } = useAuth();
  const [metrics, setMetrics] = useState<PortfolioMetrics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchMetrics();
  }, []);

  const fetchMetrics = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await portfolioService.getPortfolioMetrics();
      setMetrics(data);
    } catch (err: any) {
      console.error('Failed to fetch portfolio metrics:', err);
      setError('Failed to load portfolio metrics');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-8">
        <div className="bg-[#ef4444]/10 border border-[#ef4444]/50 rounded-lg p-4">
          <p className="text-[#ef4444]">{error}</p>
        </div>
      </div>
    );
  }

  if (!metrics) {
    return (
      <div className="p-8">
        <h1 className="text-3xl font-bold text-white mb-4">Portfolio</h1>
        <p className="text-gray-400">No portfolio data available</p>
      </div>
    );
  }

  // Convert breakdown objects to arrays for charts
  const countryBreakdownData = Object.entries(metrics.breakdown_by_country).map(
    ([country, breakdown]) => ({
      name: country,
      value: breakdown.value,
      percentage: breakdown.percentage,
    })
  );

  const sectorBreakdownData = Object.entries(metrics.breakdown_by_sector).map(
    ([sector, breakdown]) => ({
      name: sector,
      value: breakdown.value,
      percentage: breakdown.percentage,
    })
  );

  const assetTypeBreakdownData = Object.entries(metrics.breakdown_by_asset_type).map(
    ([assetType, breakdown]) => ({
      name: assetType.toUpperCase(),
      value: breakdown.value,
      percentage: breakdown.percentage,
    })
  );

  return (
    <div className="p-4 sm:p-6 lg:p-8 space-y-6 lg:space-y-8 pt-16 lg:pt-8">
      {/* Header */}
      <div>
        <h1 className="text-2xl sm:text-3xl font-bold text-white mb-2">Portfolio Overview</h1>
        <p className="text-sm sm:text-base text-gray-400">
          Welcome back, {user?.name || 'there'}! Here's your investment summary.
        </p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-4 lg:gap-6">
        <PortfolioMetricsCard
          title="Total Value"
          value={formatCurrency(metrics.total_value, metrics.currency)}
          subtitle={`${metrics.investment_count} investments`}
          icon={<CurrencyDollarIcon className="w-6 h-6 sm:w-8 sm:h-8" />}
        />

        <PortfolioMetricsCard
          title="Total Cost"
          value={formatCurrency(metrics.total_cost, metrics.currency)}
          subtitle="Total invested"
          icon={<BanknotesIcon className="w-6 h-6 sm:w-8 sm:h-8" />}
        />

        <PortfolioMetricsCard
          title="Total Gain/Loss"
          value={formatCurrency(metrics.total_gain_loss, metrics.currency)}
          subtitle="Overall performance"
          icon={<ChartBarIcon className="w-6 h-6 sm:w-8 sm:h-8" />}
          trend={
            metrics.total_gain_loss > 0 ? 'up' : metrics.total_gain_loss < 0 ? 'down' : 'neutral'
          }
          trendValue={formatPercentage(metrics.total_gain_loss_percent)}
        />

        <PortfolioMetricsCard
          title="Return"
          value={formatPercentage(metrics.total_gain_loss_percent)}
          subtitle="Percentage return"
          icon={<TrophyIcon className="w-6 h-6 sm:w-8 sm:h-8" />}
          trend={
            metrics.total_gain_loss_percent > 0
              ? 'up'
              : metrics.total_gain_loss_percent < 0
              ? 'down'
              : 'neutral'
          }
        />

        <PortfolioMetricsCard
          title="Diversification"
          value={metrics.diversification_score.toFixed(1)}
          subtitle="Out of 100"
          icon={<ScaleIcon className="w-6 h-6 sm:w-8 sm:h-8" />}
        />
      </div>

      {/* Portfolio Value History */}
      <PortfolioHistoryChart currency={metrics.currency} />

      {/* Breakdown Charts - All Three */}
      <div>
        <h2 className="text-xl sm:text-2xl font-bold text-white mb-4">Portfolio Breakdown</h2>
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 lg:gap-6">
          {assetTypeBreakdownData.length > 0 && (
            <BreakdownChart title="By Asset Type" data={assetTypeBreakdownData} />
          )}

          {countryBreakdownData.length > 0 && (
            <BreakdownChart title="By Country" data={countryBreakdownData} />
          )}

          {sectorBreakdownData.length > 0 && (
            <BreakdownChart title="By Sector" data={sectorBreakdownData} />
          )}
        </div>
      </div>

      {/* Performers Tables */}
      {(metrics.top_performers.length > 0 || metrics.worst_performers.length > 0) && (
        <div>
          <h2 className="text-xl sm:text-2xl font-bold text-white mb-4">Performance Leaders</h2>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 lg:gap-6">
            {metrics.top_performers.length > 0 && (
              <PerformersTable
                title="Top Performers"
                performers={metrics.top_performers.map((p) => ({
                  symbol: p.symbol,
                  name: p.name,
                  gain_loss_percent: p.gain_loss_percent,
                }))}
                type="top"
              />
            )}

            {metrics.worst_performers.length > 0 && (
              <PerformersTable
                title="Worst Performers"
                performers={metrics.worst_performers.map((p) => ({
                  symbol: p.symbol,
                  name: p.name,
                  gain_loss_percent: p.gain_loss_percent,
                }))}
                type="worst"
              />
            )}
          </div>
        </div>
      )}
    </div>
  );
}
