import { useState, useEffect } from 'react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, ReferenceLine, Line } from 'recharts';
import { format, subMonths, subYears, parseISO } from 'date-fns';
import { Card } from '@components/common/Card';
import { LoadingSpinner } from '@components/common/LoadingSpinner';
import { investmentsService } from '@services/investmentsService';
import { portfolioService } from '@services/portfolioService';
import { formatCurrency } from '@utils/formatters';
import type { PortfolioHistoryPoint } from '@/types';

interface PortfolioHistoryChartProps {
  currency?: string;
}

type TimeRange = '1M' | '3M' | '6M' | '1Y' | 'ALL';

export function PortfolioHistoryChart({ currency = 'USD' }: PortfolioHistoryChartProps) {
  const [data, setData] = useState<PortfolioHistoryPoint[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [timeRange, setTimeRange] = useState<TimeRange>('3M');
  const [investmentEvents, setInvestmentEvents] = useState<Record<string, string[]>>({});
  const [showPortfolioValue, setShowPortfolioValue] = useState(true);
  const [showGainLoss, setShowGainLoss] = useState(true);

  useEffect(() => {
    fetchHistory();
  }, [timeRange]);

  const fetchHistory = async () => {
    setLoading(true);
    setError(null);

    try {
      const now = new Date();
      let startDate: Date;

      switch (timeRange) {
        case '1M':
          startDate = subMonths(now, 1);
          break;
        case '3M':
          startDate = subMonths(now, 3);
          break;
        case '6M':
          startDate = subMonths(now, 6);
          break;
        case '1Y':
          startDate = subYears(now, 1);
          break;
        case 'ALL':
          startDate = subYears(now, 10); // Fetch last 10 years for "ALL"
          break;
      }

      const [response, investments] = await Promise.all([
        portfolioService.getPortfolioHistory({
          start_date: format(startDate, 'yyyy-MM-dd'),
          end_date: format(now, 'yyyy-MM-dd'),
        }),
        investmentsService.getUserInvestments({ active_only: true, limit: 1000 }),
      ]);

      const eventsByDate: Record<string, Set<string>> = {};
      for (const investment of investments) {
        if (!investment.purchase_date) {
          continue;
        }
        let purchaseDate: Date;
        try {
          purchaseDate = parseISO(investment.purchase_date);
        } catch {
          continue;
        }
        if (purchaseDate < startDate || purchaseDate > now) {
          continue;
        }
        const dateKey = format(purchaseDate, 'yyyy-MM-dd');
        if (!eventsByDate[dateKey]) {
          eventsByDate[dateKey] = new Set();
        }
        const label = investment.name
          ? `${investment.symbol} - ${investment.name}`
          : investment.symbol;
        eventsByDate[dateKey].add(label);
      }

      const normalizedEvents: Record<string, string[]> = {};
      Object.keys(eventsByDate).forEach((dateKey) => {
        normalizedEvents[dateKey] = Array.from(eventsByDate[dateKey]).sort();
      });

      console.log('Investment events:', normalizedEvents);
      console.log('Chart data points (first 5):', response.data_points.slice(0, 5));
      console.log('Investments:', investments.slice(0, 3));

      setData(response.data_points);
      setInvestmentEvents(normalizedEvents);
    } catch (err: any) {
      console.error('Failed to fetch portfolio history:', err);
      setError('Failed to load portfolio history');
    } finally {
      setLoading(false);
    }
  };

  const timeRanges: TimeRange[] = ['1M', '3M', '6M', '1Y', 'ALL'];

  const formatXAxis = (timestamp: string) => {
    try {
      const date = parseISO(timestamp);
      if (timeRange === '1M') {
        return format(date, 'MMM d');
      }
      return format(date, 'MMM yyyy');
    } catch {
      return timestamp;
    }
  };

  const investmentGuideDates = Object.keys(investmentEvents).sort();
  console.log('Investment guide dates to render:', investmentGuideDates);

  const InvestmentLabel = (props: any) => {
    const { viewBox } = props;
    if (!viewBox) return null;

    return (
      <g>
        <circle
          cx={viewBox.x}
          cy={viewBox.y + 10}
          r={4}
          fill="#f59e0b"
          stroke="#fbbf24"
          strokeWidth={2}
        />
      </g>
    );
  };

  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      const dataPoint = payload[0].payload;
      const dateKey = format(parseISO(dataPoint.timestamp), 'yyyy-MM-dd');
      const investmentsForDate = investmentEvents[dateKey] || [];
      const gainLoss = dataPoint.total_gain_loss || 0;
      const portfolioValueColor = isPositive ? '#10b981' : '#ef4444';

      return (
        <div className="bg-[#151932] border border-[#1f2544] rounded-lg p-3 shadow-xl">
          <p className="text-sm text-gray-400 mb-1">
            {format(parseISO(dataPoint.timestamp), 'MMM d, yyyy')}
          </p>
          {showPortfolioValue && (
            <p className="text-base font-bold" style={{ color: portfolioValueColor }}>
              Portfolio: {formatCurrency(dataPoint.total_value, currency)}
            </p>
          )}
          {showGainLoss && (
            <p className="text-sm font-medium text-[#3b82f6]">
              Gain/Loss: {formatCurrency(gainLoss, currency)}
            </p>
          )}
          {investmentsForDate.length > 0 && (
            <div className="mt-2">
              <p className="text-xs uppercase tracking-wide text-[#22d3ee]">Investissements</p>
              <ul className="mt-1 text-sm text-gray-200">
                {investmentsForDate.map((label) => (
                  <li key={label}>{label}</li>
                ))}
              </ul>
            </div>
          )}
        </div>
      );
    }
    return null;
  };

  if (loading) {
    return (
      <Card>
        <div className="flex items-center justify-center h-80">
          <LoadingSpinner size="lg" />
        </div>
      </Card>
    );
  }

  if (error) {
    return (
      <Card>
        <div className="flex items-center justify-center h-80">
          <p className="text-[#ef4444]">{error}</p>
        </div>
      </Card>
    );
  }

  if (!data || data.length === 0) {
    return (
      <Card>
        <h3 className="text-lg font-semibold text-white mb-4">Portfolio Value History</h3>
        <div className="flex items-center justify-center h-64">
          <p className="text-gray-400">No portfolio history available</p>
        </div>
      </Card>
    );
  }

  // Calculate gain/loss for gradient color
  const firstValue = data[0]?.total_value || 0;
  const lastValue = data[data.length - 1]?.total_value || 0;
  const isPositive = lastValue >= firstValue;

  return (
    <Card>
      <div className="mb-4 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h3 className="text-base sm:text-lg font-semibold text-white mb-2">Portfolio Value History</h3>
          <div className="flex flex-wrap gap-2 sm:gap-4 text-xs">
            <button
              onClick={() => setShowPortfolioValue(!showPortfolioValue)}
              className="flex items-center gap-2 cursor-pointer hover:opacity-80 transition-opacity"
            >
              <div className={`w-3 h-0.5 ${isPositive ? 'bg-[#10b981]' : 'bg-[#ef4444]'} ${!showPortfolioValue ? 'opacity-30' : ''}`}></div>
              <span className={`${showPortfolioValue ? 'text-gray-400' : 'text-gray-600'}`}>Portfolio Value</span>
            </button>
            <button
              onClick={() => setShowGainLoss(!showGainLoss)}
              className="flex items-center gap-2 cursor-pointer hover:opacity-80 transition-opacity"
            >
              <div className={`w-3 h-0.5 bg-[#3b82f6] ${!showGainLoss ? 'opacity-30' : ''}`}></div>
              <span className={`${showGainLoss ? 'text-gray-400' : 'text-gray-600'}`}>Total Gain/Loss</span>
            </button>
          </div>
        </div>
        <div className="flex flex-wrap gap-1 sm:gap-2">
          {timeRanges.map((range) => (
            <button
              key={range}
              onClick={() => setTimeRange(range)}
              className={`px-2 sm:px-3 py-1 rounded-lg text-xs sm:text-sm font-medium transition-all duration-200 ${
                timeRange === range
                  ? 'bg-[#22d3ee] text-white shadow-lg shadow-[#22d3ee]/20'
                  : 'bg-[#0a0e27] text-gray-400 hover:text-gray-200 hover:bg-[#252b4a]'
              }`}
            >
              {range}
            </button>
          ))}
        </div>
      </div>

      <ResponsiveContainer width="100%" height={320}>
        <AreaChart data={data}>
          <defs>
            <linearGradient id="colorPortfolioValue" x1="0" y1="0" x2="0" y2="1">
              <stop
                offset="5%"
                stopColor={isPositive ? '#10b981' : '#ef4444'}
                stopOpacity={0.3}
              />
              <stop
                offset="95%"
                stopColor={isPositive ? '#10b981' : '#ef4444'}
                stopOpacity={0}
              />
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" stroke="#1f2544" />
          <XAxis
            dataKey="timestamp"
            tickFormatter={formatXAxis}
            stroke="#6b7280"
            style={{ fontSize: '12px' }}
          />
          {showPortfolioValue && (
            <YAxis
              yAxisId="left"
              tickFormatter={(value) => formatCurrency(value, currency)}
              stroke="#6b7280"
              style={{ fontSize: '12px' }}
            />
          )}
          {showGainLoss && (
            <YAxis
              yAxisId="right"
              orientation="right"
              tickFormatter={(value) => formatCurrency(value, currency)}
              stroke="#3b82f6"
              style={{ fontSize: '12px' }}
            />
          )}
          <Tooltip content={<CustomTooltip />} />
          {showGainLoss && (
            <ReferenceLine
              yAxisId="right"
              y={0}
              stroke="#3b82f6"
              strokeDasharray="4 4"
              strokeOpacity={0.5}
            />
          )}
          {investmentGuideDates.map((dateKey) => {
            console.log('Rendering ReferenceLine for:', dateKey);
            return (
              <ReferenceLine
                key={dateKey}
                x={dateKey}
                stroke="#f59e0b"
                strokeDasharray="3 3"
                strokeWidth={2}
                strokeOpacity={0.8}
                label={<InvestmentLabel />}
              />
            );
          })}
          {showPortfolioValue && (
            <Area
              yAxisId="left"
              type="monotone"
              dataKey="total_value"
              stroke={isPositive ? '#10b981' : '#ef4444'}
              strokeWidth={2}
              fill="url(#colorPortfolioValue)"
              dot={false}
              activeDot={{ r: 4, fill: isPositive ? '#10b981' : '#ef4444' }}
            />
          )}
          {showGainLoss && (
            <Line
              yAxisId="right"
              type="monotone"
              dataKey="total_gain_loss"
              stroke="#3b82f6"
              strokeWidth={2}
              dot={false}
              activeDot={{ r: 4, fill: '#3b82f6', stroke: '#3b82f6', strokeWidth: 2 }}
              isAnimationActive={false}
            />
          )}
        </AreaChart>
      </ResponsiveContainer>
    </Card>
  );
}
