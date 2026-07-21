import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/report_analytics_model.dart';

/// Shared legend chip (● label) used under the charts.
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.entries});

  /// (label, color) pairs.
  final List<(String, Color)> entries;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: entries
          .map((e) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: e.$2,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(e.$1, style: AppTextStyles.body12),
                ],
              ))
          .toList(),
    );
  }
}

String _shortLabel(String name, {int max = 10}) {
  final first = name.trim().split(RegExp(r'[\s/,]+')).first;
  return first.length <= max ? first : '${first.substring(0, max)}…';
}

/// Chart 1 — "Pass vs Fail by Project": clustered vertical bars, one Pass and
/// one Fail rod per project. Scrolls horizontally when there are many projects.
class PassFailByProjectChart extends StatelessWidget {
  const PassFailByProjectChart({super.key, required this.projects});

  final List<GroupPerformance> projects;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text('No project data.', style: AppTextStyles.body13),
        ),
      );
    }
    final maxVal = projects
        .map((p) => math.max(p.totalPass, p.totalFail))
        .fold<int>(0, math.max)
        .toDouble();
    final maxY = (maxVal <= 0 ? 1 : maxVal) * 1.15;
    final width = math.max(projects.length * 64.0, 320.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: AppColors.border, strokeWidth: 0.6),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, rodIndex) {
                        final p = projects[group.x];
                        final label = rodIndex == 0 ? 'Pass' : 'Fail';
                        return BarTooltipItem(
                          '${p.name}\n$label: ${rod.toY.toInt()}',
                          AppTextStyles.body12.copyWith(color: AppColors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, meta) => Text('${v.toInt()}',
                            style: AppTextStyles.body10),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i < 0 || i >= projects.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(_shortLabel(projects[i].name),
                                style: AppTextStyles.body10),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(projects.length, (i) {
                    final p = projects[i];
                    return BarChartGroupData(
                      x: i,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: p.totalPass.toDouble(),
                          color: AppColors.success,
                          width: 10,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        BarChartRodData(
                          toY: p.totalFail.toDouble(),
                          color: AppColors.danger,
                          width: 10,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ChartLegend(entries: [
          ('Pass', AppColors.success),
          ('Fail', AppColors.danger),
        ]),
      ],
    );
  }
}

/// Chart 2 — "Combined Score": pie of total Pass vs total Fail points.
class CombinedScorePie extends StatelessWidget {
  const CombinedScorePie({super.key, required this.pass, required this.fail});

  final int pass;
  final int fail;

  @override
  Widget build(BuildContext context) {
    final total = pass + fail;
    if (total == 0) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text('No scored points yet.', style: AppTextStyles.body13),
        ),
      );
    }
    final passPct = (pass / total) * 100;
    return Row(
      children: [
        SizedBox(
          height: 170,
          width: 170,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  value: pass.toDouble(),
                  color: AppColors.success,
                  title: '${passPct.toStringAsFixed(0)}%',
                  radius: 48,
                  titleStyle: AppTextStyles.medium12
                      .copyWith(color: AppColors.white),
                ),
                PieChartSectionData(
                  value: fail.toDouble(),
                  color: AppColors.danger,
                  title: '${(100 - passPct).toStringAsFixed(0)}%',
                  radius: 48,
                  titleStyle: AppTextStyles.medium12
                      .copyWith(color: AppColors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _legendRow('Pass', pass, AppColors.success),
              const SizedBox(height: 8),
              _legendRow('Fail', fail, AppColors.danger),
              const SizedBox(height: 8),
              Text('$total points scored', style: AppTextStyles.body12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendRow(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.body13),
        const Spacer(),
        Text('$value', style: AppTextStyles.medium13.copyWith(color: color)),
      ],
    );
  }
}

/// Chart 3 — "Pass vs Fail by Audit Point": a horizontal stacked bar per point
/// (green Pass + red Fail, width ∝ count). Horizontal keeps the long point
/// names readable, which is why the source workbook uses bar (not column) here.
class PassFailByPointChart extends StatelessWidget {
  const PassFailByPointChart({super.key, required this.points});

  final List<PointStat> points;

  @override
  Widget build(BuildContext context) {
    final scored = points.where((p) => p.scored > 0).toList();
    if (scored.isEmpty) {
      return Text('No scored audit points.', style: AppTextStyles.body13);
    }
    final maxScored =
        scored.map((p) => p.scored).fold<int>(1, math.max).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...scored.map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(p.name,
                        style: AppTextStyles.body12,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 16,
                        child: Row(
                          children: [
                            if (p.pass > 0)
                              Expanded(
                                flex: (p.pass / maxScored * 1000).round(),
                                child: Container(color: AppColors.success),
                              ),
                            if (p.fail > 0)
                              Expanded(
                                flex: (p.fail / maxScored * 1000).round(),
                                child: Container(color: AppColors.danger),
                              ),
                            // Remainder keeps bars comparable across rows.
                            Expanded(
                              flex: ((maxScored - p.scored) / maxScored * 1000)
                                  .round()
                                  .clamp(0, 1000),
                              child: const SizedBox(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 56,
                    child: Text('${p.pass} / ${p.fail}',
                        textAlign: TextAlign.right,
                        style: AppTextStyles.body12),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 10),
        ChartLegend(entries: [
          ('Pass', AppColors.success),
          ('Fail', AppColors.danger),
        ]),
        const SizedBox(height: 2),
        Text('Values shown as Pass / Fail (count of projects).',
            style: AppTextStyles.body11.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}

/// Chart 4 — "Pareto Analysis — Failure Points": fail-count bars + a cumulative
/// % line. The two fl_chart layers are aligned by giving both identical
/// reserved sizes and using BarChartAlignment.spaceAround with the line's
/// x-range set to [-0.5, n-0.5] so bar centres and line points coincide.
class ParetoChart extends StatelessWidget {
  const ParetoChart({super.key, required this.points});

  final List<PointStat> points;

  static const double _left = 30;
  static const double _right = 34;
  static const double _bottom = 30;

  @override
  Widget build(BuildContext context) {
    final data = points.where((p) => p.fail > 0).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
    if (data.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text('No failures recorded — nothing to rank.',
              style: AppTextStyles.body13),
        ),
      );
    }
    final n = data.length;
    final maxFail = data.map((p) => p.fail).fold<int>(1, math.max).toDouble();
    final maxY = maxFail * 1.15;
    final width = math.max(n * 46.0, 340.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 250,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Stack(
                children: [
                  // Layer 1 — fail-count bars (left axis).
                  BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: AppColors.border, strokeWidth: 0.6),
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, _, rod, __) {
                            final p = data[group.x];
                            return BarTooltipItem(
                              '#${p.rank} ${p.name}\n'
                              'Fail: ${p.fail} · Cum: ${p.cumulativePercent.toStringAsFixed(0)}%',
                              AppTextStyles.body12
                                  .copyWith(color: AppColors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(
                                showTitles: false, reservedSize: 0)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: _left,
                            getTitlesWidget: (v, meta) => Text('${v.toInt()}',
                                style: AppTextStyles.body10),
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(
                                showTitles: false, reservedSize: _right)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: _bottom,
                            getTitlesWidget: (v, meta) {
                              final i = v.toInt();
                              if (i < 0 || i >= n) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text('${data[i].rank}',
                                    style: AppTextStyles.body10),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(n, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: data[i].fail.toDouble(),
                              color: AppColors.danger,
                              width: 14,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                  // Layer 2 — cumulative % line (right axis). Same reserved
                  // sizes + x-range [-0.5, n-0.5] aligns points to bar centres.
                  LineChart(
                    LineChartData(
                      minX: -0.5,
                      maxX: n - 0.5,
                      minY: 0,
                      maxY: 100,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(
                                showTitles: false, reservedSize: 0)),
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                                showTitles: false, reservedSize: _left)),
                        bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(
                                showTitles: false, reservedSize: _bottom)),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: _right,
                            interval: 25,
                            getTitlesWidget: (v, meta) => Text('${v.toInt()}%',
                                style: AppTextStyles.body10),
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            n,
                            (i) => FlSpot(
                                i.toDouble(), data[i].cumulativePercent),
                          ),
                          isCurved: false,
                          color: AppColors.primary,
                          barWidth: 2,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, _, __, ___) =>
                                FlDotCirclePainter(
                              radius: 2.5,
                              color: AppColors.primary,
                              strokeWidth: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ChartLegend(entries: [
          ('Fail count', AppColors.danger),
          ('Cumulative %', AppColors.primary),
        ]),
        const SizedBox(height: 2),
        Text('X-axis = points ranked by failures (rank #). '
            'Left = fail count, right = cumulative share of all failures.',
            style: AppTextStyles.body11.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}
