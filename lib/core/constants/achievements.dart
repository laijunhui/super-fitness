import '../../data/models/achievement_model.dart';

/// 成就配置
class AchievementConfig {
  AchievementConfig._();

  static final List<Achievement> all = [
    // 连续打卡
    Achievement(
      type: AchievementType.consecutiveDays3,
      name: '初露头角',
      description: '连续运动3天',
      icon: '🌱',
      requiredValue: 3,
    ),
    Achievement(
      type: AchievementType.consecutiveDays7,
      name: '持之以恒',
      description: '连续运动7天',
      icon: '🌿',
      requiredValue: 7,
    ),
    Achievement(
      type: AchievementType.consecutiveDays30,
      name: '运动达人',
      description: '连续运动30天',
      icon: '🌳',
      requiredValue: 30,
    ),

    // 里程类
    Achievement(
      type: AchievementType.totalDistance10,
      name: '初出茅庐',
      description: '累计跑步10公里',
      icon: '🏃',
      requiredValue: 10,
    ),
    Achievement(
      type: AchievementType.totalDistance50,
      name: '渐入佳境',
      description: '累计跑步50公里',
      icon: '🏅',
      requiredValue: 50,
    ),
    Achievement(
      type: AchievementType.totalDistance100,
      name: '百里挑一',
      description: '累计跑步100公里',
      icon: '⭐',
      requiredValue: 100,
    ),
    Achievement(
      type: AchievementType.totalDistance500,
      name: '千里之行',
      description: '累计跑步500公里',
      icon: '🏆',
      requiredValue: 500,
    ),

    // 次数类
    Achievement(
      type: AchievementType.exerciseCount10,
      name: '小试牛刀',
      description: '运动10次',
      icon: '💪',
      requiredValue: 10,
    ),
    Achievement(
      type: AchievementType.exerciseCount50,
      name: '勤学苦练',
      description: '运动50次',
      icon: '🔥',
      requiredValue: 50,
    ),
    Achievement(
      type: AchievementType.exerciseCount100,
      name: '身经百战',
      description: '运动100次',
      icon: '🎖️',
      requiredValue: 100,
    ),

    // 时长类
    Achievement(
      type: AchievementType.totalDuration10h,
      name: '挥汗如雨',
      description: '累计运动10小时',
      icon: '⏱️',
      requiredValue: 10,
    ),
    Achievement(
      type: AchievementType.totalDuration50h,
      name: '持之以恒',
      description: '累计运动50小时',
      icon: '⌛',
      requiredValue: 50,
    ),

    // 运动类型专属
    Achievement(
      type: AchievementType.running10km,
      name: '长跑健将',
      description: '单次跑步10公里',
      icon: '🏃‍♂️',
      requiredValue: 10,
    ),
    Achievement(
      type: AchievementType.cycling30km,
      name: '骑行高手',
      description: '单次骑行30公里',
      icon: '🚴‍♂️',
      requiredValue: 30,
    ),
  ];
}
