import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/achievements.dart';
import '../../data/models/achievement_model.dart';
import '../../data/models/exercise_model.dart';
import '../../domain/repositories/exercise_repository.dart';

/// 成就状态管理
class AchievementProvider extends ChangeNotifier {
  final ExerciseRepository _exerciseRepository;
  late SharedPreferences _prefs;

  List<Achievement> _achievements = [];
  bool _isLoading = false;
  Achievement? _newlyUnlocked;
  bool _initialized = false;

  AchievementProvider({required ExerciseRepository exerciseRepository})
      : _exerciseRepository = exerciseRepository;

  // Getters
  List<Achievement> get achievements => _achievements;
  bool get isLoading => _isLoading;
  Achievement? get newlyUnlocked => _newlyUnlocked;
  bool get isInitialized => _initialized;

  /// 已解锁成就数量
  int get unlockedCount => _achievements.where((a) => a.isUnlocked).length;

  /// 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await loadAchievements();
    _initialized = true;
  }

  /// 加载成就数据
  Future<void> loadAchievements() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 从存储中加载已解锁成就
      final unlockedMap = _loadUnlockedAchievements();

      // 初始化所有成就
      _achievements = AchievementConfig.all.map((base) {
        final unlockedAt = unlockedMap[base.type];
        return Achievement(
          type: base.type,
          name: base.name,
          description: base.description,
          icon: base.icon,
          requiredValue: base.requiredValue,
          unlockedAt: unlockedAt,
        );
      }).toList();

      // 检查新成就
      await _checkAndUnlockNewAchievements();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 从存储中加载已解锁成就
  Map<AchievementType, DateTime> _loadUnlockedAchievements() {
    final Map<AchievementType, DateTime> result = {};
    final jsonStr = _prefs.getString('unlocked_achievements');
    if (jsonStr != null) {
      try {
        final Map<String, dynamic> map = json.decode(jsonStr);
        for (final entry in map.entries) {
          final type = AchievementType.values.firstWhere(
            (e) => e.name == entry.key,
            orElse: () => AchievementType.consecutiveDays3,
          );
          result[type] = DateTime.parse(entry.value);
        }
      } catch (e) {
        debugPrint('Error loading achievements: $e');
      }
    }
    return result;
  }

  /// 保存已解锁成就
  Future<void> _saveUnlockedAchievements() async {
    final Map<String, String> map = {};
    for (final achievement in _achievements) {
      if (achievement.isUnlocked) {
        map[achievement.type.name] = achievement.unlockedAt!.toIso8601String();
      }
    }
    await _prefs.setString('unlocked_achievements', json.encode(map));
  }

  /// 检查并解锁新成就
  Future<void> _checkAndUnlockNewAchievements() async {
    final exercises = await _exerciseRepository.getAllExercises();

    for (final achievement in _achievements) {
      if (achievement.isUnlocked) continue;

      bool shouldUnlock = false;

      switch (achievement.type) {
        case AchievementType.consecutiveDays3:
        case AchievementType.consecutiveDays7:
        case AchievementType.consecutiveDays30:
          shouldUnlock = _checkConsecutiveDays(
            exercises,
            achievement.requiredValue,
          );
          break;

        case AchievementType.totalDistance10:
        case AchievementType.totalDistance50:
        case AchievementType.totalDistance100:
        case AchievementType.totalDistance500:
          shouldUnlock = _checkTotalDistance(
            exercises,
            achievement.requiredValue.toDouble(),
          );
          break;

        case AchievementType.exerciseCount10:
        case AchievementType.exerciseCount50:
        case AchievementType.exerciseCount100:
          shouldUnlock = _checkExerciseCount(
            exercises,
            achievement.requiredValue,
          );
          break;

        case AchievementType.totalDuration10h:
        case AchievementType.totalDuration50h:
          shouldUnlock = _checkTotalDuration(
            exercises,
            achievement.requiredValue.toDouble(),
          );
          break;

        case AchievementType.running10km:
          shouldUnlock = _checkSingleExerciseDistance(
            exercises,
            ExerciseType.running,
            achievement.requiredValue.toDouble(),
          );
          break;

        case AchievementType.cycling30km:
          shouldUnlock = _checkSingleExerciseDistance(
            exercises,
            ExerciseType.cycling,
            achievement.requiredValue.toDouble(),
          );
          break;
      }

      if (shouldUnlock) {
        await _unlockAchievement(achievement.type);
      }
    }
  }

  /// 检查连续运动天数
  bool _checkConsecutiveDays(List<ExerciseModel> exercises, int days) {
    if (exercises.isEmpty) return false;

    // 按日期分组
    final Set<String> exerciseDates = {};
    for (final exercise in exercises) {
      final date = DateTime(
        exercise.createdAt.year,
        exercise.createdAt.month,
        exercise.createdAt.day,
      );
      exerciseDates.add('${date.year}-${date.month}-${date.day}');
    }

    // 转换为日期列表并排序
    final sortedDates = exerciseDates.toList()..sort();

    if (sortedDates.isEmpty) return false;

    // 检查从最近一天往前数是否有连续days天
    int consecutiveCount = 1;
    DateTime? lastDate;

    for (int i = sortedDates.length - 1; i >= 0; i--) {
      final parts = sortedDates[i].split('-');
      final currentDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      if (lastDate == null) {
        lastDate = currentDate;
        continue;
      }

      final diff = lastDate.difference(currentDate).inDays;
      if (diff == 1) {
        consecutiveCount++;
        if (consecutiveCount >= days) return true;
      } else if (diff > 1) {
        // 连续中断
        break;
      }
      lastDate = currentDate;
    }

    return consecutiveCount >= days;
  }

  /// 检查总里程
  bool _checkTotalDistance(List<ExerciseModel> exercises, double distance) {
    final total = exercises.fold(
      0.0,
      (sum, e) => sum + e.distance,
    );
    return total >= distance;
  }

  /// 检查运动次数
  bool _checkExerciseCount(List<ExerciseModel> exercises, int count) {
    return exercises.length >= count;
  }

  /// 检查总时长（小时）
  bool _checkTotalDuration(List<ExerciseModel> exercises, double hours) {
    final totalMinutes = exercises.fold(
      0,
      (sum, e) => sum + e.duration,
    );
    return totalMinutes >= hours * 60;
  }

  /// 检查单次运动距离
  bool _checkSingleExerciseDistance(
    List<ExerciseModel> exercises,
    ExerciseType type,
    double distance,
  ) {
    return exercises.any((e) => e.type == type && e.distance >= distance);
  }

  /// 解锁成就
  Future<void> _unlockAchievement(AchievementType type) async {
    final index = _achievements.indexWhere((a) => a.type == type);
    if (index != -1) {
      _achievements[index] = _achievements[index].copyWith(
        unlockedAt: DateTime.now(),
      );
      _newlyUnlocked = _achievements[index];
      await _saveUnlockedAchievements();
      notifyListeners();
    }
  }

  /// 清除新成就提示
  void clearNewlyUnlocked() {
    _newlyUnlocked = null;
    notifyListeners();
  }

  /// 检查并刷新成就（每次添加运动后调用）
  Future<void> checkAchievements() async {
    await _checkAndUnlockNewAchievements();
  }
}
