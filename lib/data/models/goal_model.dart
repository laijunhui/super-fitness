import '../../core/constants/app_constants.dart';

/// 目标类型
enum GoalType {
  distance,  // 距离（km）
  duration,  // 时长（分钟）
  calories, // 卡路里（kcal）
}

/// 目标类型扩展
extension GoalTypeExtension on GoalType {
  String get displayName {
    switch (this) {
      case GoalType.distance:
        return '距离';
      case GoalType.duration:
        return '时长';
      case GoalType.calories:
        return '卡路里';
    }
  }

  String get unit {
    switch (this) {
      case GoalType.distance:
        return 'km';
      case GoalType.duration:
        return '分钟';
      case GoalType.calories:
        return 'kcal';
    }
  }
}

/// 运动目标
class ExerciseGoal {
  final String id;
  final ExerciseType type;
  final GoalType goalType;
  final double targetValue;
  final DateTime createdAt;
  final bool isCompleted;

  ExerciseGoal({
    required this.id,
    required this.type,
    required this.goalType,
    required this.targetValue,
    required this.createdAt,
    this.isCompleted = false,
  });

  ExerciseGoal copyWith({
    String? id,
    ExerciseType? type,
    GoalType? goalType,
    double? targetValue,
    DateTime? createdAt,
    bool? isCompleted,
  }) {
    return ExerciseGoal(
      id: id ?? this.id,
      type: type ?? this.type,
      goalType: goalType ?? this.goalType,
      targetValue: targetValue ?? this.targetValue,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// 提醒
class Reminder {
  final String id;
  final int hour;      // 小时（0-23）
  final int minute;    // 分钟（0-59）
  final List<int> weekdays;  // 重复日期（1-7，周一至周日）
  final bool isEnabled;
  final String? label;  // 提醒标签

  Reminder({
    required this.id,
    required this.hour,
    required this.minute,
    required this.weekdays,
    this.isEnabled = true,
    this.label,
  });

  /// 获取时间字符串
  String get timeString {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// 获取星期字符串
  String get weekdaysString {
    if (weekdays.length == 7) return '每天';
    if (weekdays.length == 5 &&
        weekdays.contains(1) && weekdays.contains(2) &&
        weekdays.contains(3) && weekdays.contains(4) &&
        weekdays.contains(5)) {
      return '工作日';
    }
    if (weekdays.length == 2 && weekdays.contains(6) && weekdays.contains(7)) {
      return '周末';
    }
    return weekdays.map((d) {
      const dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return dayNames[d - 1];
    }).join('、');
  }

  Reminder copyWith({
    String? id,
    int? hour,
    int? minute,
    List<int>? weekdays,
    bool? isEnabled,
    String? label,
  }) {
    return Reminder(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekdays: weekdays ?? this.weekdays,
      isEnabled: isEnabled ?? this.isEnabled,
      label: label ?? this.label,
    );
  }
}
