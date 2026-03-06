import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../providers/statistics_provider.dart';
import '../../providers/theme_provider.dart';

/// 首页（统计概览）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    final statisticsProvider = context.watch<StatisticsProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => statisticsProvider.refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                _buildHeader(context, isDark),
                const SizedBox(height: 24),

                // 今日统计卡片
                _buildTodayStats(statisticsProvider, isDark),
                const SizedBox(height: 16),

                // 本周/本月统计
                _buildPeriodStats(statisticsProvider, isDark),
                const SizedBox(height: 24),

                // 快速开始运动
                _buildQuickStart(context, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '你好！',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              app_date_utils.DateUtils.formatDate(DateTime.now()),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => context.push('/statistics'),
          child: NeumorphicContainer(
            isDark: isDark,
            padding: const EdgeInsets.all(12),
            borderRadius: 12,
            child: Icon(
              Icons.bar_chart_rounded,
              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStats(StatisticsProvider provider, bool isDark) {
    final stats = provider.todayStats;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今日运动',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: '运动时长',
                value: stats.totalDuration.toString(),
                unit: '分钟',
                icon: Icons.timer_outlined,
                iconColor: AppColors.runningColor,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: '消耗热量',
                value: stats.totalCalories.toStringAsFixed(0),
                unit: 'kcal',
                icon: Icons.local_fire_department_outlined,
                iconColor: AppColors.cyclingColor,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatCard(
          title: '运动次数',
          value: stats.exerciseCount.toString(),
          unit: '次',
          icon: Icons.fitness_center_outlined,
          iconColor: primaryColor,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildPeriodStats(StatisticsProvider provider, bool isDark) {
    final weekStats = provider.weekStats;
    final monthStats = provider.monthStats;
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '本周统计',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: '本周时长',
                value: weekStats.totalDuration.toString(),
                unit: '分钟',
                icon: Icons.schedule_outlined,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: '本周距离',
                value: weekStats.totalDistance.toStringAsFixed(1),
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

  Widget _buildQuickStart(BuildContext context, bool isDark) {
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '开始运动',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: ExerciseType.values.map((type) {
            return _ExerciseTypeCard(
              type: type,
              isDark: isDark,
              onTap: () {
                if (type.requiresGps) {
                  context.push('/exercise/active', extra: type);
                } else {
                  context.push('/exercise/add', extra: type);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ExerciseTypeCard extends StatelessWidget {
  final ExerciseType type;
  final bool isDark;
  final VoidCallback onTap;

  const _ExerciseTypeCard({
    required this.type,
    required this.isDark,
    required this.onTap,
  });

  Color get _color {
    switch (type) {
      case ExerciseType.running:
        return AppColors.runningColor;
      case ExerciseType.cycling:
        return AppColors.cyclingColor;
      case ExerciseType.walking:
        return AppColors.walkingColor;
      case ExerciseType.gym:
        return AppColors.gymColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NeumorphicContainer(
        isDark: isDark,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              type.icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              type.displayName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
