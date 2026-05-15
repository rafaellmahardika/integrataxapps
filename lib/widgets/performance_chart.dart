// lib/widgets/performance_chart.dart
//
// PerformanceChart Widget
// A sleek line chart showing API response time over the last 24 hours.
// Uses fl_chart ^0.68.0 with gradient fill and custom tooltips.
//
// FIXES APPLIED:
//  [1] spotIndex in checkToShowDot  → FlDotData.checkToShowDot receives FlSpot (no
//      spotIndex). Workaround: compare spot.x against the stored _touchedIndex (the
//      x-axis index value), which is semantically equivalent.
//  [2] spotIndex in getTooltipItems → explicit `LineBarSpot` type on the lambda
//      parameter so Dart resolves spotIndex correctly (LineBarSpot extends FlSpot
//      and adds spotIndex, barIndex, bar, etc.).
//  [3] Linter prefer_const_declarations: `final minY = 0.0` → `const minY = 0.0`
//      because 0.0 is a compile-time constant value.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/data_source.dart';

class PerformanceChart extends StatefulWidget {
  final List<PerformancePoint> data;
  final double height;

  const PerformanceChart({super.key, required this.data, this.height = 180});

  @override
  State<PerformanceChart> createState() => _PerformanceChartState();
}

class _PerformanceChartState extends State<PerformanceChart>
    with SingleTickerProviderStateMixin {
  // ── Fields ────────────────────────────────────────────────────────────────

  late AnimationController _animController;
  late Animation<double> _drawAnimation;

  // Stores the x-axis index (== list index) of the currently touched data point.
  // We intentionally track x (not spotIndex) because FlDotData.checkToShowDot
  // only receives FlSpot — which lacks spotIndex. Comparing spot.x is equivalent.
  int? _touchedIndex;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _drawAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text(
            'Tidak ada data',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    final spots = _buildSpots();
    final maxY = _computeMaxY(spots);

    // FIX [3]: `0.0` is a compile-time constant → prefer `const` over `final`.
    const minY = 0.0;

    return AnimatedBuilder(
      animation: _drawAnimation,
      builder: (context, _) {
        return SizedBox(
          height: widget.height,
          child: LineChart(
            _buildChartData(spots, maxY, minY),
            duration: Duration.zero,
          ),
        );
      },
    );
  }

  // ── Chart data builder ────────────────────────────────────────────────────

  LineChartData _buildChartData(List<FlSpot> spots, double maxY, double minY) {
    return LineChartData(
      // ── Grid ──────────────────────────────────────────────────────────────
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (_) => const FlLine(
          color: AppColors.chartGrid,
          strokeWidth: 1,
          dashArray: [4, 6],
        ),
      ),

      // ── Borders ───────────────────────────────────────────────────────────
      borderData: FlBorderData(show: false),

      // ── Axis bounds ───────────────────────────────────────────────────────
      minX: 0,
      maxX: (spots.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,

      // ── Axis titles ───────────────────────────────────────────────────────
      titlesData: FlTitlesData(
        // Left axis: response time labels (ms / k)
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            interval: maxY / 4,
            getTitlesWidget: (double value, TitleMeta _) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                value >= 1000
                    ? '${(value / 1000).toStringAsFixed(1)}k'
                    : '${value.toInt()}ms',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textMuted,
                  fontFamily: 'monospace',
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ),

        // Bottom axis: hour labels (HH:00)
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: 4,
            getTitlesWidget: (double value, TitleMeta _) {
              final int idx = value.toInt();
              if (idx < 0 || idx >= widget.data.length) {
                return const SizedBox.shrink();
              }
              final int hour = widget.data[idx].hour;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textMuted,
                    fontFamily: 'monospace',
                  ),
                ),
              );
            },
          ),
        ),

        // Hide top and right axes
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),

      // ── Touch interaction & tooltip ───────────────────────────────────────
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,

        // touchCallback: LineTouchResponse.lineBarSpots is typed as
        // List<LineBarSpot>? in fl_chart 0.68.0, so .spotIndex IS available
        // on the first element here (LineBarSpot extends FlSpot + adds spotIndex).
        touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
          if (!event.isInterestedForInteractions ||
              response == null ||
              response.lineBarSpots == null ||
              response.lineBarSpots!.isEmpty) {
            setState(() => _touchedIndex = null);
            return;
          }
          setState(
            () => _touchedIndex = response.lineBarSpots!.first.spotIndex,
          );
        },

        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (LineBarSpot _) => AppColors.bgElevated,
          tooltipRoundedRadius: 10,
          tooltipBorder: const BorderSide(
            color: AppColors.borderNormal,
            width: 1,
          ),
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),

          // FIX [2]: Explicitly annotate each element as `LineBarSpot`.
          // The typedef GetLineTooltipItems = List<LineTooltipItem?>
          //   Function(List<LineBarSpot>).
          // Without the explicit type annotation on the inner `.map()` lambda,
          // Dart's type inference falls back to FlSpot (the list element
          // constraint), making `.spotIndex` unresolvable. Annotating forces
          // correct resolution.
          getTooltipItems: (List<LineBarSpot> spots) {
            return spots.map((LineBarSpot spot) {
              final int idx = spot.spotIndex;
              final int hour = (idx >= 0 && idx < widget.data.length)
                  ? widget.data[idx].hour
                  : spot.x.toInt();

              return LineTooltipItem(
                '${hour.toString().padLeft(2, '0')}:00\n',
                const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                children: [
                  TextSpan(
                    text: '${spot.y.toStringAsFixed(0)} ms',
                    style: TextStyle(
                      color: _colorForMs(spot.y),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),

      // ── Line series ───────────────────────────────────────────────────────
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: AppColors.chartLine,
          barWidth: 2.2,
          isStrokeCapRound: true,

          dotData: FlDotData(
            show: true,

            // FIX [1]: FlDotData.checkToShowDot signature is:
            //   bool Function(FlSpot spot, LineChartBarData barData)
            // FlSpot does NOT have spotIndex. We compare spot.x (== list index
            // because _buildSpots uses entry.key as x) against _touchedIndex.
            checkToShowDot: (FlSpot spot, LineChartBarData _) {
              if (_touchedIndex == null) return false;
              return spot.x == _touchedIndex!.toDouble();
            },

            getDotPainter:
                (FlSpot spot, double _, LineChartBarData __, int ___) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: _colorForMs(spot.y),
                    strokeWidth: 2,
                    strokeColor: AppColors.bgBase,
                  );
                },
          ),

          // Gradient fill under the line — uses AppColors constants (no withOpacity needed)
          belowBarData: BarAreaData(
            show: true,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.chartGradientTop, // 0x664A90D9 — opacity baked in
                AppColors.chartGradientBottom, // 0x004A90D9 — fully transparent
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Maps each [PerformancePoint] to an [FlSpot] using list index as x-value.
  List<FlSpot> _buildSpots() {
    return widget.data.asMap().entries.map((MapEntry<int, PerformancePoint> e) {
      return FlSpot(e.key.toDouble(), e.value.responseTimeMs);
    }).toList();
  }

  /// Rounds the peak y-value up to the nearest 250 ms ceiling.
  /// Clamped between 500 and 2000 ms for a sensible y-axis range.
  double _computeMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 1000;
    final double peak = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return ((peak / 250).ceil() * 250).toDouble().clamp(500, 2000);
  }

  /// Returns a severity colour based on response time in milliseconds.
  Color _colorForMs(double ms) {
    if (ms < 200) return AppColors.statusOk;
    if (ms < 500) return AppColors.statusWarning;
    return AppColors.statusError;
  }
}
