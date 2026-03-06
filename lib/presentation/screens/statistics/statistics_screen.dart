import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/statistics_provider.dart';
import '../../providers/theme_provider.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final statsProvider = context.watch<StatisticsProvider>();
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
                  _buildPeriodSelector(statsProvider, isDark),
                  const SizedBox(height: 24),

                  // 统计数据
                  _buildStats(statsProvider, isDark),
                  const SizedBox(height: 24),

                  // 图表（简化为进度条展示）
                  _buildChart(statsProvider, isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector(StatisticsProvider provider, bool isDark) {
    return Row(
      children: FilterPeriod.values.map((period) {
        final isSelected = provider.selectedPeriod == period;
        return Expanded(
          child: GestureDetector(
            onTap: () => provider.setFilterPeriod(period),
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

    final maxDuration = data.map((d) => d.totalDuration).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '每日运动时长',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((d) {
              final heightRatio = maxDuration > 0 ? d.totalDuration / maxDuration : 0.0;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 150 * heightRatio.clamp(0.05, 1.0),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
