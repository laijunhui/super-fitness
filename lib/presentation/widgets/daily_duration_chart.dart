import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../providers/statistics_provider.dart';

/// 每日运动时长柱状图组件
class DailyDurationChart extends StatefulWidget {
  final List<DailyStatsData> data;
  final bool isDark;
  final DateTime? selectedDate;
  final Function(DateTime) onBarTap;

  const DailyDurationChart({
    super.key,
    required this.data,
    required this.isDark,
    this.selectedDate,
    required this.onBarTap,
  });

  @override
  State<DailyDurationChart> createState() => _DailyDurationChartState();
}

class _DailyDurationChartState extends State<DailyDurationChart> {
  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();

    final maxDuration = widget.data
        .map((d) => d.totalDuration)
        .reduce((a, b) => a > b ? a : b);
    final maxY = maxDuration > 0 ? (maxDuration * 1.2).ceilToDouble() : 60.0;

    final isWeek = widget.data.length <= 7;
    final textColor = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final barColor = widget.isDark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 图表标题
        Text(
          '每日运动时长',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: widget.isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // 图表
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchCallback: (event, response) {
                  if (event.isInterestedForInteractions &&
                      response != null &&
                      response.spot != null) {
                    final index = response.spot!.touchedBarGroupIndex;
                    final date = widget.data[index].date;
                    widget.onBarTap(date);
                  }
                },
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: barColor.withOpacity(0.8),
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final data = widget.data[groupIndex];
                    return BarTooltipItem(
                      '${data.exerciseCount}次\n${data.totalDuration}分钟',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= widget.data.length) {
                        return const SizedBox.shrink();
                      }
                      final data = widget.data[index];
                      if (data.exerciseCount == 0 && data.totalDuration == 0) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${data.exerciseCount}|${data.totalDuration}',
                          style: TextStyle(
                            fontSize: 10,
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
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
                      final index = value.toInt();
                      if (index < 0 || index >= widget.data.length) {
                        return const SizedBox.shrink();
                      }
                      final date = widget.data[index].date;
                      String text;
                      if (isWeek) {
                        // 7天模式：显示星期几
                        text = _getWeekdayShort(date.weekday);
                      } else {
                        // 30天模式：显示日期数字
                        text = date.day.toString();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 10,
                            color: textColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: textColor.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              barGroups: _buildBarGroups(barColor, maxY),
            ),
          ),
        ),

        // Y轴单位标签
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 4),
          child: Text(
            '单位：分钟',
            style: TextStyle(
              fontSize: 10,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _buildBarGroups(Color barColor, double maxY) {
    return List.generate(widget.data.length, (index) {
      final data = widget.data[index];
      final isSelected = widget.selectedDate != null &&
          _isSameDay(data.date, widget.selectedDate!);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.totalDuration.toDouble(),
            color: isSelected ? barColor.withOpacity(0.7) : barColor,
            width: widget.data.length <= 7 ? 24 : 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: barColor.withOpacity(0.1),
            ),
          ),
        ],
      );
    });
  }

  String _getWeekdayShort(int weekday) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[weekday - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
