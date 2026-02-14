import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/portfolio.dart';
import '../../providers/portfolio_provider.dart';
import '../common/app_card.dart';
import '../common/loading_spinner.dart';

class PortfolioHistoryChart extends StatefulWidget {
  final String currency;

  const PortfolioHistoryChart({super.key, this.currency = 'USD'});

  @override
  State<PortfolioHistoryChart> createState() => _PortfolioHistoryChartState();
}

class _PortfolioHistoryChartState extends State<PortfolioHistoryChart> {
  String _selectedRange = '1Y';
  bool _showValue = true;
  bool _showGainLoss = true;

  static const _ranges = ['1M', '3M', '6M', '1Y', 'ALL'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onRangeChanged(_selectedRange);
    });
  }

  String _getStartDate() {
    final now = DateTime.now();
    return switch (_selectedRange) {
      '1M' => DateTime(now.year, now.month - 1, now.day).toIso8601String().split('T')[0],
      '3M' => DateTime(now.year, now.month - 3, now.day).toIso8601String().split('T')[0],
      '6M' => DateTime(now.year, now.month - 6, now.day).toIso8601String().split('T')[0],
      '1Y' => DateTime(now.year - 1, now.month, now.day).toIso8601String().split('T')[0],
      _ => '2000-01-01',
    };
  }

  void _onRangeChanged(String range) {
    setState(() => _selectedRange = range);
    final startDate = _getStartDate();
    context.read<PortfolioProvider>().fetchHistory(
      startDate: startDate.isNotEmpty ? startDate : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        final history = provider.history;
        final isLoading = provider.isLoadingHistory;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Portfolio Value History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Time range buttons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _ranges.map((range) {
                    final isSelected = range == _selectedRange;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _onRangeChanged(range),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.cyan.withValues(alpha: 0.2) : AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? AppColors.cyan : AppColors.border,
                            ),
                          ),
                          child: Text(
                            range,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.cyan : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              // Legend toggles
              Row(
                children: [
                  _LegendToggle(
                    label: 'Portfolio Value',
                    color: AppColors.success,
                    isActive: _showValue,
                    onTap: () => setState(() => _showValue = !_showValue),
                  ),
                  const SizedBox(width: 16),
                  _LegendToggle(
                    label: 'Gain/Loss',
                    color: const Color(0xFF3B82F6),
                    isActive: _showGainLoss,
                    onTap: () => setState(() => _showGainLoss = !_showGainLoss),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Chart
              SizedBox(
                height: 250,
                child: isLoading
                    ? const Center(child: LoadingSpinner())
                    : history == null || history.dataPoints.isEmpty
                        ? const Center(
                            child: Text(
                              'No data available',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : _buildChart(history.dataPoints),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChart(List<PortfolioHistoryPoint> data) {
    if (data.isEmpty) return const SizedBox();

    final firstDate = data.first.date;
    final valueSpots = <FlSpot>[];
    final gainLossSpots = <FlSpot>[];

    double minValue = double.infinity;
    double maxValue = double.negativeInfinity;
    double minGainLoss = double.infinity;
    double maxGainLoss = double.negativeInfinity;

    for (final point in data) {
      final x = point.date.difference(firstDate).inHours.toDouble();
      if (_showValue) {
        valueSpots.add(FlSpot(x, point.totalValue));
        if (point.totalValue < minValue) minValue = point.totalValue;
        if (point.totalValue > maxValue) maxValue = point.totalValue;
      }
      if (_showGainLoss) {
        gainLossSpots.add(FlSpot(x, point.totalGainLoss));
        if (point.totalGainLoss < minGainLoss) minGainLoss = point.totalGainLoss;
        if (point.totalGainLoss > maxGainLoss) maxGainLoss = point.totalGainLoss;
      }
    }

    final lineBars = <LineChartBarData>[];

    if (_showValue && valueSpots.isNotEmpty) {
      final isPositive = data.last.totalValue >= data.first.totalValue;
      final color = isPositive ? AppColors.success : AppColors.danger;
      lineBars.add(LineChartBarData(
        spots: valueSpots,
        isCurved: true,
        color: color,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: color.withValues(alpha: 0.1),
        ),
      ));
    }

    if (_showGainLoss && gainLossSpots.isNotEmpty) {
      lineBars.add(LineChartBarData(
        spots: gainLossSpots,
        isCurved: true,
        color: const Color(0xFF3B82F6),
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ));
    }

    if (lineBars.isEmpty) return const SizedBox();

    return LineChart(
      LineChartData(
        lineBarsData: lineBars,
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: _calcInterval(minValue, maxValue),
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border.withValues(alpha: 0.5),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: _showValue,
              reservedSize: 60,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  formatCompactCurrency(value, widget.currency),
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ),
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: _showGainLoss,
              reservedSize: 60,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  formatCompactCurrency(value, widget.currency),
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _calcXInterval(data),
              getTitlesWidget: (value, meta) {
                final date = firstDate.add(Duration(hours: value.toInt()));
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('MMM d').format(date),
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surface,
            tooltipBorder: const BorderSide(color: AppColors.border),
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final date = firstDate.add(Duration(hours: spot.x.toInt()));
                final label = spot.barIndex == 0 && _showValue ? 'Value' : 'G/L';
                return LineTooltipItem(
                  '${DateFormat('MMM d, yyyy').format(date)}\n$label: ${formatCurrency(spot.y, widget.currency)}',
                  const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  double _calcInterval(double min, double max) {
    final range = max - min;
    if (range <= 0) return 1;
    return (range / 4).ceilToDouble();
  }

  double _calcXInterval(List<PortfolioHistoryPoint> data) {
    if (data.length < 2) return 1;
    final totalHours = data.last.date.difference(data.first.date).inHours;
    return (totalHours / 5).ceilToDouble();
  }
}

class _LegendToggle extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _LegendToggle({
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isActive ? color : Colors.transparent,
              border: Border.all(color: color),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? AppColors.textSecondary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
