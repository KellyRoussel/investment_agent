import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from 'recharts';
import { Card } from '@components/common/Card';

interface ChartDataPoint {
  name: string;
  value: number;
  percentage: number;
}

interface BreakdownChartProps {
  title: string;
  data: ChartDataPoint[];
  colors?: string[];
}

const DEFAULT_COLORS = [
  '#22d3ee', // Cyan
  '#a78bfa', // Purple
  '#f472b6', // Pink
  '#10b981', // Green
  '#f59e0b', // Amber
  '#3b82f6', // Blue
  '#ef4444', // Red
  '#8b5cf6', // Violet
  '#14b8a6', // Teal
  '#f97316', // Orange
];

export function BreakdownChart({ title, data, colors = DEFAULT_COLORS }: BreakdownChartProps) {
  if (!data || data.length === 0) {
    return (
      <Card>
        <h3 className="text-lg font-semibold text-white mb-4">{title}</h3>
        <div className="flex items-center justify-center h-64">
          <p className="text-gray-400">No data available</p>
        </div>
      </Card>
    );
  }

  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      const data = payload[0];
      return (
        <div className="bg-[#151932] border border-[#1f2544] rounded-lg p-3 shadow-xl">
          <p className="text-sm font-medium text-white mb-1">{data.name}</p>
          <p className="text-sm text-gray-400">
            {data.value.toLocaleString('en-US', {
              style: 'currency',
              currency: 'USD',
            })}
          </p>
          <p className="text-xs text-gray-400 mt-1">{data.payload.percentage.toFixed(1)}%</p>
        </div>
      );
    }
    return null;
  };

  const legendItems = data.map((entry, index) => ({
    ...entry,
    color: colors[index % colors.length],
  }));

  return (
    <Card>
      <h3 className="text-lg font-semibold text-white mb-4">{title}</h3>
      <ResponsiveContainer width="100%" height={280}>
        <PieChart>
          <Pie
            data={data}
            cx="50%"
            cy="50%"
            labelLine={false}
            label={false}
            outerRadius={78}
            fill="#8884d8"
            dataKey="value"
          >
            {data.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={colors[index % colors.length]} />
            ))}
          </Pie>
          <Tooltip content={<CustomTooltip />} />
        </PieChart>
      </ResponsiveContainer>
      <div className="flex flex-wrap gap-3 justify-center mt-4">
        {legendItems.map((entry, index) => (
          <div key={`legend-${index}`} className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full" style={{ backgroundColor: entry.color }} />
            <span className="text-sm text-gray-400">{entry.name}</span>
            <span className="text-xs text-gray-500">({entry.percentage.toFixed(1)}%)</span>
          </div>
        ))}
      </div>
    </Card>
  );
}
