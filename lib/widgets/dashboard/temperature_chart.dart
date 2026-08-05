import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_theme.dart';

/// A modern line chart widget for displaying temperature and humidity history
/// Supports multiple data series with customizable colors and legends
class TemperatureChart extends StatelessWidget {
  final List<ChartDataSeries> dataSeries;
  final String? title;
  final bool showLegend;
  final double height;
  final bool showGrid;

  const TemperatureChart({
    super.key,
    required this.dataSeries,
    this.title,
    this.showLegend = true,
    this.height = 200,
    this.showGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    if (dataSeries.isEmpty) {
      return Container(
        height: height,
        decoration: AppTheme.cardDecoration,
        child: const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (title != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen, size: 20),
                  onPressed: () {
                    // Could expand to full screen view
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: AppTheme.textSecondary,
                ),
              ],
            ),

          if (title != null) const SizedBox(height: AppTheme.spacingM),

          // Chart
          SizedBox(
            height: height,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: showGrid,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.dividerColor.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}°',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        // Convert to date string if needed
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _formatXAxisLabel(value),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: dataSeries.map((series) => _createLineData(series)).toList(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => AppTheme.textPrimary.withValues(alpha: 0.9),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final series = dataSeries[spot.barIndex];
                        return LineTooltipItem(
                          '${series.label}: ${spot.y.toStringAsFixed(1)}${series.unit}',
                          TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                minY: _getMinY(),
                maxY: _getMaxY(),
              ),
            ),
          ),

          // Legend
          if (showLegend && dataSeries.length > 1) ...[
            const SizedBox(height: AppTheme.spacingM),
            Wrap(
              spacing: AppTheme.spacingL,
              runSpacing: AppTheme.spacingS,
              children: dataSeries.map((series) => _buildLegendItem(series)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatXAxisLabel(double value) {
    // This would be customized based on actual data
    // For now, return a simple format
    final index = value.toInt();
    return '$index:00';
  }

  double _getMinY() {
    double min = double.infinity;
    for (var series in dataSeries) {
      for (var point in series.dataPoints) {
        if (point.y < min) min = point.y;
      }
    }
    return (min - 10).clamp(0, double.infinity);
  }

  double _getMaxY() {
    double max = double.negativeInfinity;
    for (var series in dataSeries) {
      for (var point in series.dataPoints) {
        if (point.y > max) max = point.y;
      }
    }
    return max + 10;
  }

  LineChartBarData _createLineData(ChartDataSeries series) {
    return LineChartBarData(
      spots: series.dataPoints.map((p) => FlSpot(p.x, p.y)).toList(),
      isCurved: true,
      curveSmoothness: 0.3,
      color: series.color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: series.showArea,
        color: series.color.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildLegendItem(ChartDataSeries series) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: series.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          series.label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Data model for a chart series
class ChartDataSeries {
  final String label;
  final List<ChartDataPoint> dataPoints;
  final Color color;
  final String unit;
  final bool showArea;

  ChartDataSeries({
    required this.label,
    required this.dataPoints,
    required this.color,
    this.unit = '°',
    this.showArea = false,
  });

  factory ChartDataSeries.temperature(String label, List<ChartDataPoint> points) {
    return ChartDataSeries(
      label: label,
      dataPoints: points,
      color: AppTheme.temperatureOrange,
      unit: '°C',
    );
  }

  factory ChartDataSeries.humidity(String label, List<ChartDataPoint> points) {
    return ChartDataSeries(
      label: label,
      dataPoints: points,
      color: AppTheme.humidityBlue,
      unit: '%',
    );
  }
}

/// Single data point for the chart
class ChartDataPoint {
  final double x;
  final double y;
  final DateTime? timestamp;

  ChartDataPoint({
    required this.x,
    required this.y,
    this.timestamp,
  });

  factory ChartDataPoint.fromReading(int index, double value, {DateTime? time}) {
    return ChartDataPoint(
      x: index.toDouble(),
      y: value,
      timestamp: time,
    );
  }
}

/// Simple sparkline chart for compact display in cards
class SparklineChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double height;
  final double strokeWidth;

  const SparklineChart({
    super.key,
    required this.data,
    this.color = AppTheme.temperatureOrange,
    this.height = 40,
    this.strokeWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(height: height);

    final spots = data.asMap().entries.map((e) => 
      FlSpot(e.key.toDouble(), e.value)
    ).toList();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.4,
              color: color,
              barWidth: strokeWidth,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
