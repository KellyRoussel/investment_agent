import { useState, useEffect } from 'react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { format, subMonths, subYears, parseISO } from 'date-fns';
import { Card } from '@components/common/Card';
import { LoadingSpinner } from '@components/common/LoadingSpinner';
import { portfolioService } from '@services/portfolioService';
import { formatCurrency } from '@utils/formatters';
import type { PortfolioHistoryPoint } from '@types/index';

interface PortfolioHistoryChartProps {
  currency?: string;
}

type TimeRange = '1M' | '3M' | '6M' | '1Y' | 'ALL';

export function PortfolioHistoryChart({ currency = 'USD' }: PortfolioHistoryChartProps) {
  const [data, setData] = useState<PortfolioHistoryPoint[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [timeRange, setTimeRange] = useState<TimeRange>('3M');

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

      const response = await portfolioService.getPortfolioHistory({
        start_date: format(startDate, 'yyyy-MM-dd'),
        end_date: format(now, 'yyyy-MM-dd'),
      });

      setData(response.data_points);
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

  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      const dataPoint = payload[0].payload;
      return (
        <div className="bg-[#151932] border border-[#1f2544] rounded-lg p-3 shadow-xl">
          <p className="text-sm text-gray-400 mb-1">
            {format(parseISO(dataPoint.timestamp), 'MMM d, yyyy')}
          </p>
          <p className="text-base font-bold text-white">
            {formatCurrency(dataPoint.total_value, currency)}
          </p>
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
      <div className="mb-4 flex items-center justify-between">
        <h3 className="text-lg font-semibold text-white">Portfolio Value History</h3>
        <div className="flex gap-2">
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
          <YAxis
            tickFormatter={(value) => formatCurrency(value, currency)}
            stroke="#6b7280"
            style={{ fontSize: '12px' }}
          />
          <Tooltip content={<CustomTooltip />} />
          <Area
            type="monotone"
            dataKey="total_value"
            stroke={isPositive ? '#10b981' : '#ef4444'}
            strokeWidth={2}
            fill="url(#colorPortfolioValue)"
            dot={false}
            activeDot={{ r: 4, fill: isPositive ? '#10b981' : '#ef4444' }}
          />
        </AreaChart>
      </ResponsiveContainer>
    </Card>
  );
}
