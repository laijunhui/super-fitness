import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../data/models/exercise_model.dart';
import '../../domain/repositories/exercise_repository.dart';

/// 统计数据模型
class Statistics {
  final int exerciseCount;
  final int totalDuration;
  final double totalCalories;
  final double totalDistance;

  Statistics({
    this.exerciseCount = 0,
    this.totalDuration = 0,
    this.totalCalories = 0,
    this.totalDistance = 0,
  });

  Statistics copyWith({
    int? exerciseCount,
    int? totalDuration,
    double? totalCalories,
    double? totalDistance,
  }) {
    return Statistics(
      exerciseCount: exerciseCount ?? this.exerciseCount,
      totalDuration: totalDuration ?? this.totalDuration,
      totalCalories: totalCalories ?? this.totalCalories,
      totalDistance: totalDistance ?? this.totalDistance,
    );
  }
}

/// 数据统计状态管理
class StatisticsProvider extends ChangeNotifier {
  final ExerciseRepository _exerciseRepository;

  Statistics _todayStats = Statistics();
  Statistics _weekStats = Statistics();
  Statistics _monthStats = Statistics();
  FilterPeriod _selectedPeriod = FilterPeriod.week;
  bool _isLoading = false;
  List<DailyStatsData> _dailyStatsData = [];

  StatisticsProvider({required ExerciseRepository exerciseRepository})
      : _exerciseRepository = exerciseRepository;

  // Getters
  Statistics get todayStats => _todayStats;
  Statistics get weekStats => _weekStats;
  Statistics get monthStats => _monthStats;
  FilterPeriod get selectedPeriod => _selectedPeriod;
  bool get isLoading => _isLoading;
  List<DailyStatsData> get dailyStatsData => _dailyStatsData;

  Statistics get currentStats {
    switch (_selectedPeriod) {
      case FilterPeriod.week:
        return _weekStats;
      case FilterPeriod.month:
        return _monthStats;
    }
  }

  /// 切换筛选周期
  void setFilterPeriod(FilterPeriod period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  /// 加载所有统计数据
  Future<void> loadStatistics() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 加载今日统计
      final todayExercises = await _exerciseRepository.getTodayExercises();
      _todayStats = _calculateStats(todayExercises);

      // 加载本周统计
      final weekExercises = await _exerciseRepository.getWeekExercises();
      _weekStats = _calculateStats(weekExercises);

      // 加载本月统计
      final monthExercises = await _exerciseRepository.getMonthExercises();
      _monthStats = _calculateStats(monthExercises);

      // 加载每日统计数据（用于图表）
      await _loadDailyStats();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 计算统计数据
  Statistics _calculateStats(List<ExerciseModel> exercises) {
    if (exercises.isEmpty) {
      return Statistics();
    }

    int totalDuration = 0;
    double totalCalories = 0;
    double totalDistance = 0;

    for (final exercise in exercises) {
      totalDuration += exercise.duration;
      totalCalories += exercise.calories;
      totalDistance += exercise.distance;
    }

    return Statistics(
      exerciseCount: exercises.length,
      totalDuration: totalDuration,
      totalCalories: totalCalories,
      totalDistance: totalDistance,
    );
  }

  /// 加载每日统计数据
  Future<void> _loadDailyStats() async {
    final days = _selectedPeriod == FilterPeriod.week ? 7 : 30;
    final startDate = app_date_utils.DateUtils.getDaysAgo(days - 1);
    final endDate = DateTime.now();

    final exercises = await _exerciseRepository.getExercisesByDateRange(
      startDate,
      endDate,
    );

    // 按日期分组
    final Map<String, List<ExerciseModel>> grouped = {};
    for (final exercise in exercises) {
      final dateKey = app_date_utils.DateUtils.formatDate(exercise.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(exercise);
    }

    // 生成每日统计数据
    _dailyStatsData = [];
    for (int i = 0; i < days; i++) {
      final date = app_date_utils.DateUtils.getDaysAgo(days - 1 - i);
      final dateKey = app_date_utils.DateUtils.formatDate(date);
      final dayExercises = grouped[dateKey] ?? [];

      _dailyStatsData.add(DailyStatsData(
        date: date,
        exerciseCount: dayExercises.length,
        totalDuration: dayExercises.fold(0, (sum, e) => sum + e.duration),
        totalCalories: dayExercises.fold(0.0, (sum, e) => sum + e.calories),
        totalDistance: dayExercises.fold(0.0, (sum, e) => sum + e.distance),
      ));
    }
  }

  /// 刷新统计数据
  Future<void> refresh() async {
    await loadStatistics();
  }
}

/// 每日统计数据
class DailyStatsData {
  final DateTime date;
  final int exerciseCount;
  final int totalDuration;
  final double totalCalories;
  final double totalDistance;

  DailyStatsData({
    required this.date,
    this.exerciseCount = 0,
    this.totalDuration = 0,
    this.totalCalories = 0,
    this.totalDistance = 0,
  });
}
