import { useState, useEffect } from 'react';
import {
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Area,
  AreaChart,
  Line,
} from 'recharts';
import { format, subMonths, subYears, parseISO } from 'date-fns';
import { Card } from '@components/common/Card';
import { LoadingSpinner } from '@components/common/LoadingSpinner';
import { investmentsService } from '@services/investmentsService';
import { formatCurrency } from '@utils/formatters';
import type { PriceHistoryPoint } from '@types/index';

interface PriceHistoryChartProps {
  investmentId: string;
  currency?: string;
  purchaseDate?: string; // ISO date string, when provided shows "Since Purchase" option
  purchasePrice?: number; // Purchase price to show as reference line
}

type TimeRange = '1M' | '3M' | '6M' | '1Y' | 'ALL' | 'PURCHASE';

export function PriceHistoryChart({
  investmentId,
  currency = 'USD',
  purchaseDate,
  purchasePrice,
}: PriceHistoryChartProps) {
  const [data, setData] = useState<PriceHistoryPoint[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [timeRange, setTimeRange] = useState<TimeRange>(purchaseDate ? 'PURCHASE' : '3M');

  useEffect(() => {
    fetchPriceHistory();
  }, [investmentId, timeRange]);

  const fetchPriceHistory = async () => {
    setLoading(true);
    setError(null);

    try {
      const now = new Date();
      let startDate: Date;

      switch (timeRange) {
        case 'PURCHASE':
          if (purchaseDate) {
            startDate = parseISO(purchaseDate);
          } else {
            startDate = subMonths(now, 3);
          }
          break;
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

      const response = await investmentsService.getPriceHistory(investmentId, {
        start_date: format(startDate, 'yyyy-MM-dd'),
        end_date: format(now, 'yyyy-MM-dd'),
      });

      setData(response.data_points);
    } catch (err: any) {
      console.error('Failed to fetch price history:', err);
      setError('Failed to load price history');
    } finally {
      setLoading(false);
    }
  };

  // Build time ranges array - include "Since Purchase" if purchase date is provided
  const timeRanges: TimeRange[] = purchaseDate
    ? ['PURCHASE', '1M', '3M', '6M', '1Y', 'ALL']
    : ['1M', '3M', '6M', '1Y', 'ALL'];

  const getTimeRangeLabel = (range: TimeRange): string => {
    if (range === 'PURCHASE') return 'Since Purchase';
    return range;
  };

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

  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload;
      return (
        <div className="bg-[#151932] border border-[#1f2544] rounded-lg p-3 shadow-xl">
          <p className="text-sm text-gray-400 mb-1">
            {format(parseISO(data.timestamp), 'MMM d, yyyy')}
          </p>
          <p className="text-base font-bold text-white">
            {formatCurrency(data.price, currency)}
          </p>
          {data.volume && (
            <p className="text-xs text-gray-400 mt-1">
              Volume: {data.volume.toLocaleString()}
            </p>
          )}
        </div>
      );
    }
    return null;
  };

  if (loading) {
    return (
      <Card>
        <div className="flex items-center justify-center h-64">
          <LoadingSpinner size="lg" />
        </div>
      </Card>
    );
  }

  if (error) {
    return (
      <Card>
        <div className="flex items-center justify-center h-64">
          <p className="text-[#ef4444]">{error}</p>
        </div>
      </Card>
    );
  }

  if (!data || data.length === 0) {
    return (
      <Card>
        <div className="flex items-center justify-center h-64">
          <p className="text-gray-400">No price history available</p>
        </div>
      </Card>
    );
  }

  // Calculate gain/loss for dynamic coloring
  const firstValue = data[0]?.price || 0;
  const lastValue = data[data.length - 1]?.price || 0;
  const isPositive = lastValue >= (purchasePrice || firstValue);
  const chartColor = isPositive ? '#10b981' : '#ef4444';

  return (
    <Card>
      <div className="mb-4 flex items-center justify-between">
        <h3 className="text-lg font-semibold text-white">Price History</h3>
        <div className="flex gap-2 flex-wrap">
          {timeRanges.map((range) => (
            <button
              key={range}
              onClick={() => setTimeRange(range)}
              className={`px-3 py-1 rounded-lg text-sm font-medium transition-all duration-200 ${
                timeRange === range
                  ? 'bg-[#22d3ee] text-white shadow-lg shadow-[#22d3ee]/20'
                  : 'bg-[#0a0e27] text-gray-400 hover:text-gray-200 hover:bg-[#252b4a]'
              }`}
            >
              {getTimeRangeLabel(range)}
            </button>
          ))}
        </div>
      </div>

      <ResponsiveContainer width="100%" height={300}>
        <AreaChart data={data}>
          <defs>
            <linearGradient id="colorPriceGain" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#10b981" stopOpacity={0.3} />
              <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
            </linearGradient>
            <linearGradient id="colorPriceLoss" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#ef4444" stopOpacity={0.3} />
              <stop offset="95%" stopColor="#ef4444" stopOpacity={0} />
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" stroke="#1f2544" />
          <XAxis
            dataKey="timestamp"
            tickFormatter={formatXAxis}
            stroke="#6b7280"
            style={{ fontSize: '12px' }}
          />
          <YAxis
            tickFormatter={(value) => formatCurrency(value, currency)}
            stroke="#6b7280"
            style={{ fontSize: '12px' }}
          />
          <Tooltip content={<CustomTooltip />} />

          {/* Show purchase price reference line if provided */}
          {purchasePrice && timeRange === 'PURCHASE' && (
            <Line
              type="monotone"
              dataKey={() => purchasePrice}
              stroke="#6b7280"
              strokeWidth={1}
              strokeDasharray="5 5"
              dot={false}
              name="Purchase Price"
            />
          )}

          <Area
            type="monotone"
            dataKey="price"
            stroke={chartColor}
            strokeWidth={2}
            fill={isPositive ? 'url(#colorPriceGain)' : 'url(#colorPriceLoss)'}
            dot={false}
            activeDot={{ r: 4, fill: chartColor }}
          />
        </AreaChart>
      </ResponsiveContainer>

      {/* Show gain/loss summary when viewing since purchase */}
      {purchasePrice && timeRange === 'PURCHASE' && data.length > 0 && (
        <div className="mt-4 pt-4 border-t border-[#1f2544] flex items-center justify-between">
          <div>
            <p className="text-sm text-gray-400">Purchase Price</p>
            <p className="text-base font-medium text-white">
              {formatCurrency(purchasePrice, currency)}
            </p>
          </div>
          <div>
            <p className="text-sm text-gray-400">Current Price</p>
            <p className={`text-base font-bold ${isPositive ? 'text-[#10b981]' : 'text-[#ef4444]'}`}>
              {formatCurrency(lastValue, currency)}
            </p>
          </div>
          <div>
            <p className="text-sm text-gray-400">Change</p>
            <p className={`text-base font-bold ${isPositive ? 'text-[#10b981]' : 'text-[#ef4444]'}`}>
              {formatCurrency(lastValue - purchasePrice, currency)} (
              {((((lastValue - purchasePrice) / purchasePrice) * 100).toFixed(2))}%)
            </p>
          </div>
        </div>
      )}
    </Card>
  );
}
