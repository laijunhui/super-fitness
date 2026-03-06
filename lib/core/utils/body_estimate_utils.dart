import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/health_advice_entity.dart';

/// 身体数据估算工具
/// 当用户未录入腰围或胸围时，根据身高和性别自动估算
class BodyEstimateUtils {
  BodyEstimateUtils._();

  /// 腰围估算乘数
  static const double _maleWaistMultiplier = 0.42;
  static const double _femaleWaistMultiplier = 0.38;

  /// 胸围估算乘数
  static const double _maleChestMultiplier = 0.53;
  static const double _femaleChestMultiplier = 0.49;

  /// 估算腰围
  /// [height] 身高(cm)
  /// [gender] 性别
  /// 返回估算腰围(cm)
  static double estimateWaist(double height, Gender gender) {
    final multiplier = gender == Gender.male ? _maleWaistMultiplier : _femaleWaistMultiplier;
    return double.parse((height * multiplier).toStringAsFixed(1));
  }

  /// 估算胸围
  /// [height] 身高(cm)
  /// [gender] 性别
  /// 返回估算胸围(cm)
  static double estimateChest(double height, Gender gender) {
    final multiplier = gender == Gender.male ? _maleChestMultiplier : _femaleChestMultiplier;
    return double.parse((height * multiplier).toStringAsFixed(1));
  }

  /// 获取带估算标记的腰围值
  /// [waist] 用户输入的腰围（可为空）
  /// [height] 身高(cm)
  /// [gender] 性别
  static EstimatedValue getWaistValue(double? waist, double height, Gender gender) {
    if (waist != null && waist > 0) {
      return EstimatedValue(value: waist, isEstimated: false);
    }
    return EstimatedValue(
      value: estimateWaist(height, gender),
      isEstimated: true,
      source: '*系统生成',
    );
  }

  /// 获取带估算标记的胸围值
  /// [chest] 用户输入的胸围（可为空）
  /// [height] 身高(cm)
  /// [gender] 性别
  static EstimatedValue getChestValue(double? chest, double height, Gender gender) {
    if (chest != null && chest > 0) {
      return EstimatedValue(value: chest, isEstimated: false);
    }
    return EstimatedValue(
      value: estimateChest(height, gender),
      isEstimated: true,
      source: '*系统生成',
    );
  }
}
