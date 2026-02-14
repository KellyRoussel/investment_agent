import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/price_history.dart';
import '../../services/investments_service.dart';
import '../common/loading_spinner.dart';

class PriceHistoryChart extends StatefulWidget {
  final String investmentId;
  final double? purchasePrice;
  final String? purchaseDate;
  final String currency;
  final InvestmentsService investmentsService;

  const PriceHistoryChart({
    super.key,
    required this.investmentId,
    this.purchasePrice,
    this.purchaseDate,
    this.currency = 'USD',
    required this.investmentsService,
  });

  @override
  State<PriceHistoryChart> createState() => _PriceHistoryChartState();
}

class _PriceHistoryChartState extends State<PriceHistoryChart> {
  String _selectedRange = '1Y';
  PriceHistoryResponse? _data;
  bool _isLoading = true;

  static final _defaultRanges = ['1M', '3M', '6M', '1Y', 'ALL'];

  List<String> get _ranges {
    if (widget.purchaseDate != null) {
      return [..._defaultRanges, 'Since Purchase'];
    }
    return _defaultRanges;
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      String? startDate;
      final now = DateTime.now();

      if (_selectedRange == 'Since Purchase' && widget.purchaseDate != null) {
        startDate = widget.purchaseDate;
      } else if (_selectedRange != 'ALL') {
        final date = switch (_selectedRange) {
          '1M' => DateTime(now.year, now.month - 1, now.day),
          '3M' => DateTime(now.year, now.month - 3, now.day),
          '6M' => DateTime(now.year, now.month - 6, now.day),
          '1Y' => DateTime(now.year - 1, now.month, now.day),
          _ => now,
        };
        startDate = date.toIso8601String().split('T')[0];
      }

      _data = await widget.investmentsService.getPriceHistory(
        widget.investmentId,
        startDate: startDate,
      );
    } catch (_) {
      _data = null;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onRangeChanged(String range) {
    setState(() => _selectedRange = range);
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        const SizedBox(height: 16),

        // Chart
        SizedBox(
          height: 220,
          child: _isLoading
              ? const Center(child: LoadingSpinner())
              : _data == null || _data!.dataPoints.isEmpty
                  ? const Center(
                      child: Text('No price data available',
                          style: TextStyle(color: AppColors.textMuted)),
                    )
                  : _buildChart(_data!.dataPoints),
        ),

        // Gain/Loss summary
        if (!_isLoading && _data != null && _data!.dataPoints.isNotEmpty && widget.purchasePrice != null)
          _buildGainLossSummary(),
      ],
    );
  }

  Widget _buildChart(List<PriceHistoryPoint> data) {
    final firstDate = data.first.date;
    final spots = data.map((p) {
      final x = p.date.difference(firstDate).inHours.toDouble();
      return FlSpot(x, p.price);
    }).toList();

    final isUp = data.last.price >= data.first.price;
    final color = isUp ? AppColors.success : AppColors.danger;

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.1),
            ),
          ),
        ],
        extraLinesData: widget.purchasePrice != null
            ? ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: widget.purchasePrice!,
                    color: AppColors.warning,
                    strokeWidth: 1,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      labelResolver: (_) => 'Purchase',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              )
            : null,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border.withValues(alpha: 0.5),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 55,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  formatCompactCurrency(value, widget.currency),
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
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
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surface,
            tooltipBorder: const BorderSide(color: AppColors.border),
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) => spots.map((spot) {
              final date = firstDate.add(Duration(hours: spot.x.toInt()));
              return LineTooltipItem(
                '${DateFormat('MMM d, yyyy').format(date)}\n${formatCurrency(spot.y, widget.currency)}',
                const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildGainLossSummary() {
    final currentPrice = _data!.dataPoints.last.price;
    final purchasePrice = widget.purchasePrice!;
    final change = currentPrice - purchasePrice;
    final changePercent = (change / purchasePrice) * 100;
    final isPositive = change >= 0;
    final color = isPositive ? AppColors.success : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _PriceStat(
              label: 'Purchase',
              value: formatCurrency(purchasePrice, widget.currency),
            ),
            _PriceStat(
              label: 'Current',
              value: formatCurrency(currentPrice, widget.currency),
            ),
            _PriceStat(
              label: 'Change',
              value: '${formatCurrency(change, widget.currency)} (${formatPercentage(changePercent)})',
              valueColor: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PriceStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
