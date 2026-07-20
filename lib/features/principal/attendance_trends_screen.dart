import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'principal_repository.dart';

class PrincipalAttendanceTrendsScreen extends StatelessWidget {
  const PrincipalAttendanceTrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = PrincipalRepository();
    return AppShell(
      title: 'Attendance Trends',
      body: AsyncScreen<Map<String, dynamic>>(
        loader: () => repo.getAttendanceTrends(days: 30),
        builder: (context, data, refresh) {
          final s = context.surface;
          final trend = (data['dailyTrend'] as List? ?? []).cast<Map<String, dynamic>>();
          final classComparison = (data['classComparison'] as List? ?? []).cast<Map<String, dynamic>>();
          final withData = trend.where((t) => t['percent'] != null).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              Text('Daily Attendance — Last 30 Days', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
              const SizedBox(height: 10),
              if (withData.length < 2)
                SectionCard(child: Text('Not enough attendance history yet to plot a trend.', style: TextStyle(fontSize: 12, color: s.textMuted)))
              else
                SectionCard(
                  child: SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              interval: (trend.length / 5).ceilToDouble().clamp(1, double.infinity),
                              getTitlesWidget: (v, meta) {
                                final i = v.toInt();
                                if (i < 0 || i >= trend.length) return const SizedBox.shrink();
                                return Padding(padding: const EdgeInsets.only(top: 6), child: Text((trend[i]['date'] as String).substring(5), style: TextStyle(fontSize: 8.5, color: s.textMuted)));
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minY: 0,
                        maxY: 100,
                        lineBarsData: [
                          LineChartBarData(
                            spots: [for (int i = 0; i < trend.length; i++) if (trend[i]['percent'] != null) FlSpot(i.toDouble(), (trend[i]['percent'] as num).toDouble())],
                            isCurved: true,
                            color: AppColors.saffron500,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: true, color: AppColors.saffron400.withValues(alpha: 0.15)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              Text('By Class', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
              const SizedBox(height: 10),
              classComparison.isEmpty
                  ? const EmptyView(title: 'No classes yet', icon: Icons.class_outlined)
                  : SectionCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: classComparison.map((c) {
                          final pct = (c['avgAttendance'] as int?) ?? 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(c['displayName'] as String, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textPrimary), overflow: TextOverflow.ellipsis)),
                                Expanded(flex: 3, child: ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: pct / 100, minHeight: 7, backgroundColor: s.border, valueColor: const AlwaysStoppedAnimation(AppColors.saffron400)))),
                                const SizedBox(width: 8),
                                Text(c['avgAttendance'] != null ? '$pct%' : '—', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: s.textPrimary)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}
