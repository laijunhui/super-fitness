import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/statistics_model.dart';
import '../../data/models/exercise_model.dart';
import '../../domain/repositories/exercise_repository.dart';

/// 趋势数据状态管理
class TrendProvider extends ChangeNotifier {
  final ExerciseRepository _exerciseRepository;

  ExerciseTrend? _trend;
  bool _isLoading = false;
  String? _error;
  FilterPeriod _selectedPeriod = FilterPeriod.week;
  ExerciseType? _selectedType;

  TrendProvider({required ExerciseRepository exerciseRepository})
      : _exerciseRepository = exerciseRepository;

  // Getters
  ExerciseTrend? get trend => _trend;
  bool get isLoading => _isLoading;
  String? get error => _error;
  FilterPeriod get selectedPeriod => _selectedPeriod;
  ExerciseType? get selectedType => _selectedType;

  /// 设置筛选周期
  void setFilterPeriod(FilterPeriod period) {
    _selectedPeriod = period;
    loadTrend();
  }

  /// 设置运动类型筛选
  void setExerciseType(ExerciseType? type) {
    _selectedType = type;
    loadTrend();
  }

  /// 加载趋势数据
  Future<void> loadTrend() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final exercises = await _exerciseRepository.getExercisesByDateRange(
        _getStartDate(),
        DateTime.now(),
      );

      // 按运动类型筛选
      List<ExerciseModel> filteredExercises = exercises;
      if (_selectedType != null) {
        filteredExercises = exercises
            .where((e) => e.type == _selectedType)
            .toList();
      }

      // 按日期聚合数据
      final distanceData = _aggregateByDate(filteredExercises, (e) => e.distance);
      final durationData = _aggregateByDate(filteredExercises, (e) => e.duration.toDouble());
      final caloriesData = _aggregateByDate(filteredExercises, (e) => e.calories);

      _trend = ExerciseTrend(
        distanceTrend: distanceData,
        durationTrend: durationData,
        caloriesTrend: caloriesData,
        distanceDirection: _calculateDirection(distanceData),
        durationDirection: _calculateDirection(durationData),
        caloriesDirection: _calculateDirection(caloriesData),
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case FilterPeriod.week:
        return now.subtract(const Duration(days: 7));
      case FilterPeriod.month:
        return now.subtract(const Duration(days: 30));
      case FilterPeriod.quarter:
        return now.subtract(const Duration(days: 90));
    }
  }

  /// 按日期聚合数据
  List<TrendData> _aggregateByDate(
    List<ExerciseModel> exercises,
    double Function(ExerciseModel) getValue,
  ) {
    final Map<String, List<double>> dateMap = {};

    for (final exercise in exercises) {
      final dateKey = _formatDateKey(exercise.createdAt);
      dateMap.putIfAbsent(dateKey, () => []);
      dateMap[dateKey]!.add(getValue(exercise));
    }

    // 转换为趋势数据并按日期排序
    final List<TrendData> result = [];
    final sortedKeys = dateMap.keys.toList()..sort();

    for (final key in sortedKeys) {
      final values = dateMap[key]!;
      final total = values.reduce((a, b) => a + b);
      result.add(TrendData(
        date: _parseDateKey(key),
        value: total,
        type: _selectedType,
      ));
    }

    return result;
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _parseDateKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// 计算趋势方向
  TrendDirection _calculateDirection(List<TrendData> data) {
    if (data.length < 2) return TrendDirection.stable;

    final recent = data.last.value;
    final previous = data[data.length - 2].value;

    if (previous == 0) return TrendDirection.stable;

    final ratio = recent / previous;
    if (ratio > 1.2) return TrendDirection.up;
    if (ratio < 0.8) return TrendDirection.down;
    return TrendDirection.stable;
  }
}
