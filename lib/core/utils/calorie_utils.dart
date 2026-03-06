import '../constants/app_constants.dart';

/// 卡路里计算工具
class CalorieUtils {
  CalorieUtils._();

  /// 运动类型MET值（代谢当量）
  /// MET = 代谢当量，表示运动时的能量消耗相对于安静时的倍数
  static const Map<ExerciseType, double> _metValues = {
    ExerciseType.running: 9.8,    // 跑步（8km/h）
    ExerciseType.cycling: 7.5,   // 骑行（15km/h）
    ExerciseType.walking: 3.8,    // 健走（5km/h）
    ExerciseType.gym: 6.0,        // 健身（综合）
  };

  /// 默认MET值
  static const double _defaultMet = 5.0;

  /// 估算运动消耗卡路里
  /// 使用MET值估算: 卡路里 = MET × 体重(kg) × 时长(小时)
  ///
  /// [exerciseType] 运动类型
  /// [duration] 运动时长（分钟）
  /// [weight] 体重（公斤）
  static double estimateCalories({
    required ExerciseType exerciseType,
    required int duration,
    required double weight,
  }) {
    if (duration <= 0 || weight <= 0) return 0;

    final met = _metValues[exerciseType] ?? _defaultMet;
    final hours = duration / 60;
    final calories = met * weight * hours;

    return double.parse(calories.toStringAsFixed(1));
  }

  /// 获取运动类型的MET值
  static double getMetValue(ExerciseType exerciseType) {
    return _metValues[exerciseType] ?? _defaultMet;
  }

  /// 计算基础代谢率（BMR）
  /// 使用Mifflin-St Jeor公式
  ///
  /// [weight] 体重（公斤）
  /// [height] 身高（厘米）
  /// [age] 年龄
  /// [gender] 性别
  ///
  /// 男性: BMR = 10 × 体重 + 6.25 × 身高 - 5 × 年龄 + 5
  /// 女性: BMR = 10 × 体重 + 6.25 × 身高 - 5 × 年龄 - 161
  static double calculateBMR({
    required double weight,
    required double height,
    required int age,
    required Gender gender,
  }) {
    if (weight <= 0 || height <= 0 || age <= 0) return 0;

    // 基础公式: 10 × 体重 + 6.25 × 身高 - 5 × 年龄
    double bmr = 10 * weight + 6.25 * height - 5 * age;

    // 根据性别调整
    switch (gender) {
      case Gender.male:
        bmr += 5;   // 男性 +5
        break;
      case Gender.female:
        bmr -= 161; // 女性 -161
        break;
    }

    return bmr.roundToDouble();
  }

  /// 计算BMI（体质指数）
  /// BMI = 体重(kg) / 身高(m)²
  ///
  /// [weight] 体重（公斤）
  /// [height] 身高（厘米）
  static double calculateBMI({
    required double weight,
    required double height,
  }) {
    if (weight <= 0 || height <= 0) return 0;

    final heightM = height / 100; // 厘米转米
    final bmi = weight / (heightM * heightM);

    return double.parse(bmi.toStringAsFixed(1));
  }

  /// 获取BMI分类
  /// 返回BMI等级: 偏瘦、正常、偏胖、肥胖、重度肥胖
  static String getBMICategory(double bmi) {
    if (bmi <= 0) return '未知';
    if (bmi < 18.5) return '偏瘦';
    if (bmi < 24) return '正常';
    if (bmi < 28) return '偏胖';
    if (bmi < 30) return '肥胖';
    return '重度肥胖';
  }

  /// 计算体脂率（基于BMI估算）
  /// 男性: 体脂率 = (1.20 × BMI) + (0.23 × 年龄) - 16.2
  /// 女性: 体脂率 = (1.20 × BMI) + (0.23 × 年龄) - 5.4
  static double estimateBodyFat({
    required double bmi,
    required int age,
    required Gender gender,
  }) {
    if (bmi <= 0 || age <= 0) return 0;

    double bodyFat;
    switch (gender) {
      case Gender.male:
        bodyFat = (1.20 * bmi) + (0.23 * age) - 16.2;
        break;
      case Gender.female:
        bodyFat = (1.20 * bmi) + (0.23 * age) - 5.4;
        break;
    }

    // 确保结果在合理范围内
    bodyFat = bodyFat.clamp(3.0, 60.0);
    return double.parse(bodyFat.toStringAsFixed(1));
  }

  /// 计算日均总代谢（TDEE）
  /// 考虑活动系数
  ///
  /// [bmr] 基础代谢率
  /// [activityLevel] 活动水平
  static double calculateTDEE({
    required double bmr,
    required ActivityLevel activityLevel,
  }) {
    const activityMultipliers = {
      ActivityLevel.sedentary: 1.2,   // 久坐
      ActivityLevel.light: 1.375,     // 轻度活动
      ActivityLevel.moderate: 1.55,  // 中度活动
      ActivityLevel.active: 1.725,    // 活跃
      ActivityLevel.veryActive: 1.9, // 非常活跃
    };

    final multiplier = activityMultipliers[activityLevel] ?? 1.2;
    return (bmr * multiplier).roundToDouble();
  }
}
