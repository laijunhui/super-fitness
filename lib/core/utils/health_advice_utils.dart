import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/health_constants.dart';
import '../../../core/utils/body_estimate_utils.dart';
import '../../../core/utils/calorie_utils.dart';
import '../../../data/models/body_metrics_model.dart';
import '../../../domain/entities/health_advice_entity.dart';

/// 健康建议生成工具
class HealthAdviceUtils {
  HealthAdviceUtils._();

  /// 生成完整的健康建议
  static HealthAdvice generateHealthAdvice(BodyMetricsModel bodyMetrics) {
    final evaluations = _evaluateAll(bodyMetrics);
    final hasAbnormal = evaluations.any((e) => e.hasWarning);

    final bmiCategory = CalorieUtils.getBMICategory(bodyMetrics.bmi ?? 0);
    final dietAdvice = _generateDietAdvice(bodyMetrics, bmiCategory);
    final exerciseAdvice = _generateExerciseAdvice(bmiCategory);

    return HealthAdvice(
      evaluations: evaluations,
      dietAdvice: dietAdvice,
      exerciseAdvice: exerciseAdvice,
      hasAbnormalIndicators: hasAbnormal,
    );
  }

  /// 评估所有指标
  static List<HealthEvaluation> _evaluateAll(BodyMetricsModel bodyMetrics) {
    final evaluations = <HealthEvaluation>[];

    // BMI评估
    if (bodyMetrics.bmi != null) {
      evaluations.add(_evaluateBMI(bodyMetrics.bmi!));
    }

    // 体脂率评估
    if (bodyMetrics.bmi != null) {
      evaluations.add(_evaluateBodyFat(
        bodyMetrics.bmi!,
        bodyMetrics.age,
        bodyMetrics.gender,
      ));
    }

    // 腰围评估
    final waistEvaluation = _evaluateWaist(
      bodyMetrics.waist,
      bodyMetrics.height,
      bodyMetrics.gender,
    );
    if (waistEvaluation != null) {
      evaluations.add(waistEvaluation);
    }

    return evaluations;
  }

  /// 评估BMI
  static HealthEvaluation _evaluateBMI(double bmi) {
    final category = CalorieUtils.getBMICategory(bmi);
    final status = _getBMIStatus(bmi);
    final color = HealthConstants.bmiCategoryColors[category] ?? Colors.grey;

    String shortWarning;
    String detailedAdvice;

    switch (category) {
      case '偏瘦':
        shortWarning = 'BMI偏低 ($bmi)';
        detailedAdvice = '您的体重偏低，建议适当增加营养摄入，进行力量训练增肌。';
        break;
      case '正常':
        shortWarning = '';
        detailedAdvice = '您的体重在正常范围内，请继续保持健康的生活方式。';
        break;
      case '偏胖':
        shortWarning = 'BMI偏高 ($bmi)';
        detailedAdvice = '您的体重偏胖，建议适当控制饮食并增加运动量。';
        break;
      case '肥胖':
        shortWarning = 'BMI超标 ($bmi)';
        detailedAdvice = '您的体重属于肥胖范围，建议增加有氧运动并控制饮食。';
        break;
      case '重度肥胖':
        shortWarning = 'BMI严重超标 ($bmi)';
        detailedAdvice = '您的体重严重超标，建议咨询医生制定减重计划。';
        break;
      default:
        shortWarning = '';
        detailedAdvice = '';
    }

    return HealthEvaluation(
      type: IndicatorType.bmi,
      value: bmi,
      unit: '',
      status: status,
      category: category,
      shortWarning: shortWarning,
      detailedAdvice: detailedAdvice,
      statusColor: color,
    );
  }

  /// 获取BMI健康状态
  static HealthStatus _getBMIStatus(double bmi) {
    if (bmi < 18.5) return HealthStatus.low;
    if (bmi < 24) return HealthStatus.normal;
    if (bmi < 28) return HealthStatus.high;
    return HealthStatus.veryHigh;
  }

  /// 评估体脂率
  static HealthEvaluation _evaluateBodyFat(double bmi, int age, Gender gender) {
    final bodyFat = CalorieUtils.estimateBodyFat(
      bmi: bmi,
      age: age,
      gender: gender,
    );

    final ranges = gender == Gender.male
        ? HealthConstants.maleBodyFatRanges
        : HealthConstants.femaleBodyFatRanges;

    String category;
    HealthStatus status;
    Color color;

    if (bodyFat < (ranges['正常']?[0] ?? 999)) {
      category = '低';
      status = HealthStatus.low;
      color = HealthConstants.bodyFatCategoryColors['低']!;
    } else if (bodyFat < (ranges['正常']?[1] ?? 999)) {
      category = '正常';
      status = HealthStatus.normal;
      color = HealthConstants.bodyFatCategoryColors['正常']!;
    } else if (bodyFat < (ranges['偏高']?[1] ?? 999)) {
      category = '偏高';
      status = HealthStatus.high;
      color = HealthConstants.bodyFatCategoryColors['偏高']!;
    } else {
      category = '高';
      status = HealthStatus.veryHigh;
      color = HealthConstants.bodyFatCategoryColors['高']!;
    }

    String shortWarning;
    String detailedAdvice;

    switch (category) {
      case '低':
        shortWarning = '体脂率偏低 ($bodyFat%)';
        detailedAdvice = '体脂率偏低，建议适当增加营养摄入。';
        break;
      case '正常':
        shortWarning = '';
        detailedAdvice = '您的体脂率在正常范围内，请继续保持。';
        break;
      case '偏高':
        shortWarning = '体脂率偏高 ($bodyFat%)';
        detailedAdvice = '体脂率偏高，建议减少高脂肪食物摄入，增加有氧运动。';
        break;
      case '高':
        shortWarning = '体脂率过高 ($bodyFat%)';
        detailedAdvice = '体脂率过高，建议调整饮食结构并加强运动。';
        break;
      default:
        shortWarning = '';
        detailedAdvice = '';
    }

    return HealthEvaluation(
      type: IndicatorType.bodyFat,
      value: bodyFat,
      unit: '%',
      status: status,
      category: category,
      shortWarning: shortWarning,
      detailedAdvice: detailedAdvice,
      statusColor: color,
    );
  }

  /// 评估腰围
  static HealthEvaluation? _evaluateWaist(double? waist, double height, Gender gender) {
    final estimatedWaist = BodyEstimateUtils.getWaistValue(waist, height, gender);
    final waistValue = estimatedWaist.value;

    final ranges = gender == Gender.male
        ? HealthConstants.maleWaistRanges
        : HealthConstants.femaleWaistRanges;

    String category;
    HealthStatus status;
    Color color;

    if (waistValue < (ranges['正常']?[1] ?? 999)) {
      category = '正常';
      status = HealthStatus.normal;
      color = HealthConstants.waistCategoryColors['正常']!;
    } else if (waistValue < (ranges['偏高']?[1] ?? 999)) {
      category = '偏高';
      status = HealthStatus.high;
      color = HealthConstants.waistCategoryColors['偏高']!;
    } else {
      category = '高风险';
      status = HealthStatus.veryHigh;
      color = HealthConstants.waistCategoryColors['高风险']!;
    }

    String shortWarning;
    String detailedAdvice;

    switch (category) {
      case '正常':
        shortWarning = '';
        detailedAdvice = '您的腰围在正常范围内，请继续保持。';
        break;
      case '偏高':
        shortWarning = '腰围偏高 (${waistValue.toStringAsFixed(1)}cm)';
        detailedAdvice = '腰围偏高，存在一定健康风险，建议增加运动控制腰围。';
        break;
      case '高风险':
        shortWarning = '腰围超标 (${waistValue.toStringAsFixed(1)}cm)';
        detailedAdvice = '腰围超标，中心性肥胖风险较高，建议及时调整饮食和运动习惯。';
        break;
      default:
        shortWarning = '';
        detailedAdvice = '';
    }

    return HealthEvaluation(
      type: IndicatorType.waist,
      value: waistValue,
      unit: 'cm',
      status: status,
      category: category,
      shortWarning: shortWarning,
      detailedAdvice: detailedAdvice,
      statusColor: color,
      estimatedWaist: estimatedWaist,
    );
  }

  /// 生成饮食建议
  static DietAdvice _generateDietAdvice(BodyMetricsModel bodyMetrics, String bmiCategory) {
    final bmr = bodyMetrics.bmr ?? 0;
    if (bmr <= 0) {
      return const DietAdvice(
        dailyCalories: 0,
        breakfastCalories: 0,
        lunchCalories: 0,
        dinnerCalories: 0,
        snackCalories: 0,
        tips: [],
      );
    }

    // 默认使用中度活动水平计算TDEE
    final tdee = CalorieUtils.calculateTDEE(
      bmr: bmr,
      activityLevel: ActivityLevel.moderate,
    );

    // 根据BMI分类调整热量
    final adjustment = HealthConstants.calorieAdjustments[bmiCategory] ?? 0;
    final dailyCalories = tdee + adjustment;

    final breakfast = (dailyCalories * HealthConstants.mealDistribution['breakfast']!).round();
    final lunch = (dailyCalories * HealthConstants.mealDistribution['lunch']!).round();
    final dinner = (dailyCalories * HealthConstants.mealDistribution['dinner']!).round();
    final snack = (dailyCalories * HealthConstants.mealDistribution['snack']!).round();

    final tips = HealthConstants.dietTips[bmiCategory] ?? [];

    return DietAdvice(
      dailyCalories: dailyCalories.round(),
      breakfastCalories: breakfast,
      lunchCalories: lunch,
      dinnerCalories: dinner,
      snackCalories: snack,
      tips: tips,
    );
  }

  /// 生成运动建议
  static ExerciseAdvice _generateExerciseAdvice(String bmiCategory) {
    final suggestion = HealthConstants.exerciseSuggestions[bmiCategory];

    if (suggestion == null) {
      return const ExerciseAdvice(
        weeklyFrequency: 3,
        durationPerSession: 30,
        recommendedTypes: ['散步', '瑜伽'],
        tips: ['请先录入身体数据以获取个性化建议'],
      );
    }

    return ExerciseAdvice(
      weeklyFrequency: suggestion.weeklyFrequency,
      durationPerSession: suggestion.durationPerSession,
      recommendedTypes: suggestion.types,
      tips: suggestion.tips,
    );
  }

  /// 获取胸围估算值（仅展示用）
  static EstimatedValue getChestEstimate(double? chest, double height, Gender gender) {
    return BodyEstimateUtils.getChestValue(chest, height, gender);
  }
}
