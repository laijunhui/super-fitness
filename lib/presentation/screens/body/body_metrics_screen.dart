import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../domain/entities/health_advice_entity.dart';
import '../../providers/body_metrics_provider.dart';
import '../../providers/theme_provider.dart';

/// 身体指标页
class BodyMetricsScreen extends StatefulWidget {
  const BodyMetricsScreen({super.key});

  @override
  State<BodyMetricsScreen> createState() => _BodyMetricsScreenState();
}

class _BodyMetricsScreenState extends State<BodyMetricsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BodyMetricsProvider>().loadBodyMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final bodyMetricsProvider = context.watch<BodyMetricsProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('身体指标'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/body/input'),
          ),
        ],
      ),
      body: bodyMetricsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : bodyMetricsProvider.latestBodyMetrics == null
              ? _buildEmptyState(isDark)
              : _buildContent(bodyMetricsProvider, isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monitor_weight_outlined,
            size: 80,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无身体数据',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/body/input'),
            child: const Text('立即录入'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BodyMetricsProvider provider, bool isDark) {
    final metrics = provider.latestBodyMetrics!;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 主要指标
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'BMI',
                  value: metrics.bmi?.toStringAsFixed(1) ?? '-',
                  unit: '',
                  icon: Icons.monitor_weight_outlined,
                  iconColor: primaryColor,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: '基础代谢',
                  value: metrics.bmr?.toStringAsFixed(0) ?? '-',
                  unit: 'kcal',
                  icon: Icons.local_fire_department_outlined,
                  iconColor: AppColors.runningColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 体脂率和腰围
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: '体脂率',
                  value: provider.currentBodyFat?.toStringAsFixed(1) ?? '-',
                  unit: '%',
                  icon: Icons.percent_outlined,
                  iconColor: AppColors.cyclingColor,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWaistCard(provider, isDark),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 健康评估
          if (provider.healthEvaluations.isNotEmpty) ...[
            _buildSectionTitle('健康评估', isDark),
            const SizedBox(height: 12),
            ...provider.healthEvaluations
                .where((e) => e.hasWarning)
                .map((e) => _buildHealthEvaluationCard(e, isDark)),
            if (provider.healthEvaluations.every((e) => !e.hasWarning))
              _buildAllNormalCard(isDark),
            const SizedBox(height: 24),
          ],

          // 建议
          if (provider.dietAdvice != null || provider.exerciseAdvice != null) ...[
            _buildSectionTitle('建议', isDark),
            const SizedBox(height: 12),
            if (provider.dietAdvice != null)
              _buildDietAdviceCard(provider.dietAdvice!, isDark),
            const SizedBox(height: 12),
            if (provider.exerciseAdvice != null)
              _buildExerciseAdviceCard(provider.exerciseAdvice!, isDark),
            const SizedBox(height: 24),
          ],

          // 基本数据
          _buildSectionTitle('身体数据', isDark),
          const SizedBox(height: 12),
          _buildDataRow('身高', '${metrics.height.toStringAsFixed(1)} cm', isDark),
          _buildDataRow('体重', '${metrics.weight.toStringAsFixed(1)} kg', isDark),
          _buildDataRow('年龄', '${metrics.age} 岁', isDark),
          _buildDataRow('性别', metrics.gender.displayName, isDark),
          if (metrics.waist != null && metrics.waist! > 0)
            _buildDataRow('腰围', '${metrics.waist!.toStringAsFixed(1)} cm', isDark)
          else if (provider.estimatedWaist != null && provider.estimatedWaist!.isEstimated)
            _buildDataRow('腰围', '${provider.estimatedWaist!.value.toStringAsFixed(1)} cm${provider.estimatedWaist!.source ?? ''}', isDark),
          if (metrics.chest != null && metrics.chest! > 0)
            _buildDataRow('胸围', '${metrics.chest!.toStringAsFixed(1)} cm', isDark)
          else if (provider.estimatedChest != null && provider.estimatedChest!.isEstimated)
            _buildDataRow('胸围', '${provider.estimatedChest!.value.toStringAsFixed(1)} cm${provider.estimatedChest!.source ?? ''}', isDark),
        ],
      ),
    );
  }

  Widget _buildWaistCard(BodyMetricsProvider provider, bool isDark) {
    final waist = provider.estimatedWaist;
    final value = waist?.value ?? 0;
    final isEstimated = waist?.isEstimated ?? false;

    return StatCard(
      title: '腰围',
      value: value > 0 ? value.toStringAsFixed(1) : '-',
      unit: isEstimated ? '*' : 'cm',
      icon: Icons.straighten_outlined,
      iconColor: AppColors.walkingColor,
      isDark: isDark,
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
    );
  }

  Widget _buildHealthEvaluationCard(HealthEvaluation evaluation, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: evaluation.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: evaluation.statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: evaluation.statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  evaluation.shortWarning,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: evaluation.statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            evaluation.detailedAdvice,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllNormalCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightPrimary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.lightPrimary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '您的各项指标均在正常范围内，请继续保持！',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietAdviceCard(DietAdvice advice, bool isDark) {
    return NeumorphicContainer(
      isDark: isDark,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_outlined, size: 20),
              const SizedBox(width: 8),
              Text(
                '饮食建议',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '建议每日摄入约 ${advice.dailyCalories} 千卡',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildMealRow('早餐', '${advice.breakfastCalories} kcal', isDark),
          _buildMealRow('午餐', '${advice.lunchCalories} kcal', isDark),
          _buildMealRow('晚餐', '${advice.dinnerCalories} kcal', isDark),
          _buildMealRow('加餐', '${advice.snackCalories} kcal', isDark),
          if (advice.tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...advice.tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildMealRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseAdviceCard(ExerciseAdvice advice, bool isDark) {
    return NeumorphicContainer(
      isDark: isDark,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center_outlined, size: 20),
              const SizedBox(width: 8),
              Text(
                '运动建议',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '每周运动 ${advice.weeklyFrequency} 次，每次 ${advice.durationPerSession} 分钟',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: advice.recommendedTypes
                .map((type) => Chip(
                      label: Text(type, style: const TextStyle(fontSize: 12)),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
          if (advice.tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...advice.tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
