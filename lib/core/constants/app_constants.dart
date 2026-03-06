/// 运动类型枚举
enum ExerciseType {
  running,   // 跑步
  cycling,   // 骑行
  walking,   // 健走
  gym        // 健身
}

/// 活动水平枚举（用于TDEE计算）
enum ActivityLevel {
  sedentary,   // 久坐
  light,       // 轻度活动
  moderate,    // 中度活动
  active,      // 活跃
  veryActive   // 非常活跃
}

/// 性别枚举
enum Gender {
  male,
  female
}

/// 时间筛选周期
enum FilterPeriod {
  week,   // 7天
  month   // 30天
}

/// 运动类型扩展方法
extension ExerciseTypeExtension on ExerciseType {
  String get displayName {
    switch (this) {
      case ExerciseType.running:
        return '跑步';
      case ExerciseType.cycling:
        return '骑行';
      case ExerciseType.walking:
        return '健走';
      case ExerciseType.gym:
        return '健身';
    }
  }

  String get icon {
    switch (this) {
      case ExerciseType.running:
        return '🏃';
      case ExerciseType.cycling:
        return '🚴';
      case ExerciseType.walking:
        return '🚶';
      case ExerciseType.gym:
        return '💪';
    }
  }

  /// 是否需要GPS追踪
  bool get requiresGps {
    return this == ExerciseType.running ||
        this == ExerciseType.cycling ||
        this == ExerciseType.walking;
  }
}

/// 性别扩展方法
extension GenderExtension on Gender {
  String get displayName {
    switch (this) {
      case Gender.male:
        return '男性';
      case Gender.female:
        return '女性';
    }
  }
}

/// FilterPeriod扩展方法
extension FilterPeriodExtension on FilterPeriod {
  String get displayName {
    switch (this) {
      case FilterPeriod.week:
        return '7天';
      case FilterPeriod.month:
        return '30天';
    }
  }

  int get days {
    switch (this) {
      case FilterPeriod.week:
        return 7;
      case FilterPeriod.month:
        return 30;
    }
  }
}
