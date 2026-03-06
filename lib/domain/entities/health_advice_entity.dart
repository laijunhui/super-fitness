import 'package:flutter/material.dart';

/// 估算值标记
class EstimatedValue {
  final double value;
  final bool isEstimated;
  final String? source;

  const EstimatedValue({
    required this.value,
    required this.isEstimated,
    this.source,
  });
}

/// 指标类型
enum IndicatorType {
  bmi,
  bodyFat,
  waist,
  chest,
}

/// 健康状态
enum HealthStatus {
  normal,
  low,
  high,
  veryHigh,
}

/// 健康评估结果
class HealthEvaluation {
  final IndicatorType type;
  final double value;
  final String unit;
  final HealthStatus status;
  final String category;
  final String shortWarning;
  final String detailedAdvice;
  final Color statusColor;
  final EstimatedValue? estimatedWaist;
  final EstimatedValue? estimatedChest;

  const HealthEvaluation({
    required this.type,
    required this.value,
    required this.unit,
    required this.status,
    required this.category,
    required this.shortWarning,
    required this.detailedAdvice,
    required this.statusColor,
    this.estimatedWaist,
    this.estimatedChest,
  });

  /// 是否需要显示警告
  bool get hasWarning => status != HealthStatus.normal;
}

/// 饮食建议
class DietAdvice {
  final int dailyCalories;
  final int breakfastCalories;
  final int lunchCalories;
  final int dinnerCalories;
  final int snackCalories;
  final List<String> tips;

  const DietAdvice({
    required this.dailyCalories,
    required this.breakfastCalories,
    required this.lunchCalories,
    required this.dinnerCalories,
    required this.snackCalories,
    required this.tips,
  });
}

/// 运动建议
class ExerciseAdvice {
  final int weeklyFrequency;
  final int durationPerSession;
  final List<String> recommendedTypes;
  final List<String> tips;

  const ExerciseAdvice({
    required this.weeklyFrequency,
    required this.durationPerSession,
    required this.recommendedTypes,
    required this.tips,
  });
}

/// 健康建议综合结果
class HealthAdvice {
  final List<HealthEvaluation> evaluations;
  final DietAdvice? dietAdvice;
  final ExerciseAdvice? exerciseAdvice;
  final bool hasAbnormalIndicators;

  const HealthAdvice({
    required this.evaluations,
    this.dietAdvice,
    this.exerciseAdvice,
    required this.hasAbnormalIndicators,
  });
}
