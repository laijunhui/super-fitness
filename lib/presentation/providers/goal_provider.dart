import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/goal_model.dart';
import '../../domain/repositories/exercise_repository.dart';

/// 运动目标和提醒状态管理
class GoalProvider extends ChangeNotifier {
  final ExerciseRepository _exerciseRepository;
  final _uuid = const Uuid();
  late SharedPreferences _prefs;

  ExerciseGoal? _currentGoal;
  List<Reminder> _reminders = [];
  final bool _isLoading = false;
  bool _initialized = false;

  GoalProvider({required ExerciseRepository exerciseRepository})
      : _exerciseRepository = exerciseRepository;

  // Getters
  ExerciseGoal? get currentGoal => _currentGoal;
  List<Reminder> get reminders => _reminders;
  bool get isLoading => _isLoading;
  bool get isInitialized => _initialized;

  /// 获取目标进度（0.0-1.0）
  /// 注意：这是一个异步计算，需要调用 calculateProgressAsync
  double get goalProgress {
    return 0.0; // 默认值，实际计算使用 calculateProgressAsync
  }

  /// 异步计算目标进度
  Future<double> calculateProgressAsync() async {
    if (_currentGoal == null) return 0.0;

    final exercises = await _exerciseRepository.getAllExercises();
    double currentValue = 0.0;

    switch (_currentGoal!.goalType) {
      case GoalType.distance:
        currentValue = exercises
            .where((e) => e.type == _currentGoal!.type)
            .fold(0.0, (sum, e) => sum + e.distance);
        break;
      case GoalType.duration:
        currentValue = exercises
            .where((e) => e.type == _currentGoal!.type)
            .fold(0.0, (sum, e) => sum + e.duration);
        break;
      case GoalType.calories:
        currentValue = exercises
            .where((e) => e.type == _currentGoal!.type)
            .fold(0.0, (sum, e) => sum + e.calories);
        break;
    }

    final progress = currentValue / _currentGoal!.targetValue;
    return progress.clamp(0.0, 1.0);
  }

  /// 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadGoal();
    await _loadReminders();
    _initialized = true;
    notifyListeners();
  }

  /// 加载保存的目标
  Future<void> _loadGoal() async {
    final goalJson = _prefs.getString('current_goal');
    if (goalJson != null) {
      try {
        final map = json.decode(goalJson) as Map<String, dynamic>;
        _currentGoal = ExerciseGoal(
          id: map['id'],
          type: ExerciseType.values.firstWhere(
            (e) => e.name == map['type'],
            orElse: () => ExerciseType.running,
          ),
          goalType: GoalType.values.firstWhere(
            (e) => e.name == map['goalType'],
            orElse: () => GoalType.distance,
          ),
          targetValue: map['targetValue'],
          createdAt: DateTime.parse(map['createdAt']),
          isCompleted: map['isCompleted'] ?? false,
        );
      } catch (e) {
        debugPrint('Error loading goal: $e');
      }
    }
  }

  /// 加载保存的提醒
  Future<void> _loadReminders() async {
    final remindersJson = _prefs.getString('reminders');
    if (remindersJson != null) {
      try {
        final list = json.decode(remindersJson) as List;
        _reminders = list.map((map) {
          return Reminder(
            id: map['id'],
            hour: map['hour'],
            minute: map['minute'],
            weekdays: List<int>.from(map['weekdays']),
            isEnabled: map['isEnabled'] ?? true,
            label: map['label'],
          );
        }).toList();
      } catch (e) {
        debugPrint('Error loading reminders: $e');
      }
    }
  }

  /// 保存目标
  Future<void> _saveGoal() async {
    if (_currentGoal == null) {
      await _prefs.remove('current_goal');
      return;
    }
    final map = {
      'id': _currentGoal!.id,
      'type': _currentGoal!.type.name,
      'goalType': _currentGoal!.goalType.name,
      'targetValue': _currentGoal!.targetValue,
      'createdAt': _currentGoal!.createdAt.toIso8601String(),
      'isCompleted': _currentGoal!.isCompleted,
    };
    await _prefs.setString('current_goal', json.encode(map));
  }

  /// 保存提醒列表
  Future<void> _saveReminders() async {
    final list = _reminders.map((r) => {
      'id': r.id,
      'hour': r.hour,
      'minute': r.minute,
      'weekdays': r.weekdays,
      'isEnabled': r.isEnabled,
      'label': r.label,
    }).toList();
    await _prefs.setString('reminders', json.encode(list));
  }

  /// 设置运动目标
  Future<void> setGoal({
    required ExerciseType type,
    required GoalType goalType,
    required double targetValue,
  }) async {
    _currentGoal = ExerciseGoal(
      id: _uuid.v4(),
      type: type,
      goalType: goalType,
      targetValue: targetValue,
      createdAt: DateTime.now(),
    );
    await _saveGoal();
    notifyListeners();
  }

  /// 清除目标
  Future<void> clearGoal() async {
    _currentGoal = null;
    await _saveGoal();
    notifyListeners();
  }

  /// 添加提醒
  Future<void> addReminder({
    required int hour,
    required int minute,
    required List<int> weekdays,
    String? label,
  }) async {
    final reminder = Reminder(
      id: _uuid.v4(),
      hour: hour,
      minute: minute,
      weekdays: weekdays,
      label: label,
    );
    _reminders.add(reminder);
    await _saveReminders();
    notifyListeners();
  }

  /// 删除提醒
  Future<void> removeReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    await _saveReminders();
    notifyListeners();
  }

  /// 切换提醒开关
  Future<void> toggleReminder(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(
        isEnabled: !_reminders[index].isEnabled,
      );
      await _saveReminders();
      notifyListeners();
    }
  }

  /// 更新提醒
  Future<void> updateReminder(Reminder reminder) async {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      _reminders[index] = reminder;
      await _saveReminders();
      notifyListeners();
    }
  }
}
