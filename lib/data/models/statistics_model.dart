import '../../core/constants/app_constants.dart';

/// 趋势数据点
class TrendData {
  final DateTime date;
  final double value;
  final ExerciseType? type;

  TrendData({
    required this.date,
    required this.value,
    this.type,
  });
}

/// 运动趋势数据
class ExerciseTrend {
  final List<TrendData> distanceTrend;
  final List<TrendData> durationTrend;
  final List<TrendData> caloriesTrend;
  final TrendDirection distanceDirection;
  final TrendDirection durationDirection;
  final TrendDirection caloriesDirection;

  ExerciseTrend({
    required this.distanceTrend,
    required this.durationTrend,
    required this.caloriesTrend,
    required this.distanceDirection,
    required this.durationDirection,
    required this.caloriesDirection,
  });
}

/// 趋势方向
enum TrendDirection {
  up,    // 上升
  down,  // 下降
  stable // 平稳
}

/// 趋势方向扩展方法
extension TrendDirectionExtension on TrendDirection {
  String get displayText {
    switch (this) {
      case TrendDirection.up:
        return '上升';
      case TrendDirection.down:
        return '下降';
      case TrendDirection.stable:
        return '平稳';
    }
  }

  String get icon {
    switch (this) {
      case TrendDirection.up:
        return '↑';
      case TrendDirection.down:
        return '↓';
      case TrendDirection.stable:
        return '→';
    }
  }
}
