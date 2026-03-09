/// 成就类型
enum AchievementType {
  // 连续打卡类
  consecutiveDays3,   // 连续3天
  consecutiveDays7,   // 连续7天
  consecutiveDays30,  // 连续30天

  // 里程类
  totalDistance10,   // 总里程10km
  totalDistance50,   // 总里程50km
  totalDistance100,  // 总里程100km
  totalDistance500,  // 总里程500km

  // 次数类
  exerciseCount10,    // 运动10次
  exerciseCount50,    // 运动50次
  exerciseCount100,   // 运动100次

  // 时长类
  totalDuration10h,  // 累计10小时
  totalDuration50h,  // 累计50小时

  // 运动类型专属
  running10km,       // 单次跑步10km
  cycling30km,       // 单次骑行30km
}

/// 成就
class Achievement {
  final AchievementType type;
  final String name;
  final String description;
  final String icon;
  final int requiredValue;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  Achievement({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.requiredValue,
    this.unlockedAt,
  });

  Achievement copyWith({
    AchievementType? type,
    String? name,
    String? description,
    String? icon,
    int? requiredValue,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      requiredValue: requiredValue ?? this.requiredValue,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

/// 用户成就数据
class UserAchievements {
  final Map<AchievementType, DateTime> unlockedAchievements;
  final int totalPoints;

  UserAchievements({
    required this.unlockedAchievements,
    required this.totalPoints,
  });
}
