import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/statistics_provider.dart';
import '../../providers/trend_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/daily_duration_chart.dart';
import '../../widgets/exercise_map_card.dart';
import '../../widgets/trend_chart.dart';

/// 数据统计页
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsProvider>().loadStatistics();
      context.read<TrendProvider>().loadTrend();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final statsProvider = context.watch<StatisticsProvider>();
    final trendProvider = context.watch<TrendProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据统计'),
      ),
      body: statsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 周期选择
                  _buildPeriodSelector(statsProvider, trendProvider, isDark),
                  const SizedBox(height: 24),

                  // 统计数据
                  _buildStats(statsProvider, isDark),
                  const SizedBox(height: 24),

                  // 趋势图表
                  _buildTrendCharts(trendProvider, isDark),
                  const SizedBox(height: 24),

                  // 每日运动图表
                  _buildChart(statsProvider, isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector(StatisticsProvider statsProvider, TrendProvider trendProvider, bool isDark) {
    return Row(
      children: FilterPeriod.values.map((period) {
        final isSelected = statsProvider.selectedPeriod == period;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              statsProvider.setFilterPeriod(period);
              trendProvider.setFilterPeriod(period);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  period.displayName,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建趋势图表
  Widget _buildTrendCharts(TrendProvider provider, bool isDark) {
    final trend = provider.trend;
    if (trend == null || provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '趋势分析',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 16),
        // 距离趋势
        TrendChart(
          data: trend.distanceTrend,
          lineColor: AppColors.runningColor,
          title: '距离趋势',
          unit: 'km',
          direction: trend.distanceDirection,
        ),
        const SizedBox(height: 24),
        // 时长趋势
        TrendChart(
          data: trend.durationTrend,
          lineColor: AppColors.cyclingColor,
          title: '时长趋势',
          unit: '分钟',
          direction: trend.durationDirection,
        ),
        const SizedBox(height: 24),
        // 卡路里趋势
        TrendChart(
          data: trend.caloriesTrend,
          lineColor: AppColors.walkingColor,
          title: '卡路里趋势',
          unit: 'kcal',
          direction: trend.caloriesDirection,
        ),
      ],
    );
  }

  Widget _buildStats(StatisticsProvider provider, bool isDark) {
    final stats = provider.currentStats;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: '运动次数',
                value: stats.exerciseCount.toString(),
                unit: '次',
                icon: Icons.fitness_center_outlined,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: '运动时长',
                value: stats.totalDuration.toString(),
                unit: '分钟',
                icon: Icons.timer_outlined,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: '消耗热量',
                value: stats.totalCalories.toStringAsFixed(0),
                unit: 'kcal',
                icon: Icons.local_fire_department_outlined,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: '运动距离',
                value: stats.totalDistance.toStringAsFixed(1),
                unit: 'km',
                icon: Icons.straighten_outlined,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart(StatisticsProvider provider, bool isDark) {
    final data = provider.dailyStatsData;
    if (data.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 柱状图
        DailyDurationChart(
          data: data,
          isDark: isDark,
          selectedDate: provider.selectedDate,
          onBarTap: (date) {
            // 如果点击的是已选中的日期，则清除选中
            if (provider.selectedDate != null &&
                provider.selectedDate!.year == date.year &&
                provider.selectedDate!.month == date.month &&
                provider.selectedDate!.day == date.day) {
              provider.clearSelection();
            } else {
              provider.selectDate(date);
            }
          },
        ),

        // 选中日期的运动记录列表
        if (provider.hasSelectedDate) ...[
          const SizedBox(height: 16),
          _buildSelectedDateExerciseList(provider, isDark),
        ],
      ],
    );
  }

  /// 构建选中日期的运动记录列表
  Widget _buildSelectedDateExerciseList(StatisticsProvider provider, bool isDark) {
    final selectedDate = provider.selectedDate!;
    final exercises = provider.selectedDateExercises;

    // 格式化日期
    final dateStr = '${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 折叠按钮
          GestureDetector(
            onTap: () => provider.clearSelection(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkPrimary.withOpacity(0.1)
                    : AppColors.lightPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$dateStr 的运动记录',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${exercises.length}条',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 记录列表
          if (exercises.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.directions_run_outlined,
                      size: 48,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '当日无运动记录',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return ExerciseMapCard(
                  exercise: exercise,
                  isDark: isDark,
                  onTap: () => context.push('/exercise/${exercise.id}'),
                );
              },
            ),
        ],
      ),
    );
  }
}
