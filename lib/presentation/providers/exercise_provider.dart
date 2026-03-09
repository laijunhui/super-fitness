import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/calorie_utils.dart';
import '../../core/utils/distance_utils.dart';
import '../../data/models/exercise_model.dart';
import '../../domain/repositories/exercise_repository.dart';

/// 运动记录状态管理
class ExerciseProvider extends ChangeNotifier {
  final ExerciseRepository _exerciseRepository;
  final _uuid = const Uuid();

  List<ExerciseModel> _exercises = [];
  bool _isLoading = false;
  String? _error;
  ExerciseModel? _currentExercise;

  // 实时运动状态
  bool _isTracking = false;
  List<GPSPoint> _trackingPoints = [];
  DateTime? _trackingStartTime;
  ExerciseType? _trackingType;
  double _currentWeight = 70; // 默认体重
  bool _gpsEnabled = false;
  String? _gpsError;

  ExerciseProvider({required ExerciseRepository exerciseRepository})
      : _exerciseRepository = exerciseRepository;

  // Getters
  List<ExerciseModel> get exercises => _exercises;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ExerciseModel? get currentExercise => _currentExercise;
  bool get isTracking => _isTracking;
  List<GPSPoint> get trackingPoints => _trackingPoints;
  DateTime? get trackingStartTime => _trackingStartTime;
  ExerciseType? get trackingType => _trackingType;
  bool get gpsEnabled => _gpsEnabled;
  String? get gpsError => _gpsError;

  /// 获取实时运动时长（秒）
  int get trackingDuration {
    if (_trackingStartTime == null) return 0;
    return DateTime.now().difference(_trackingStartTime!).inSeconds;
  }

  /// 获取实时运动距离（米）
  double get trackingDistance {
    return DistanceUtils.calculateTotalDistance(
      _trackingPoints.map((p) => {
        'latitude': p.latitude,
        'longitude': p.longitude,
      }).toList(),
    );
  }

  /// 获取实时卡路里消耗
  double get trackingCalories {
    if (_trackingType == null) return 0;
    return CalorieUtils.estimateCalories(
      exerciseType: _trackingType!,
      duration: trackingDuration ~/ 60,
      weight: _currentWeight,
    );
  }

  /// 设置当前体重（用于卡路里计算）
  void setCurrentWeight(double weight) {
    _currentWeight = weight;
  }

  /// 加载所有运动记录
  Future<void> loadExercises() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _exercises = await _exerciseRepository.getAllExercises();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 添加运动记录
  Future<void> addExercise({
    required ExerciseType type,
    required double distance,
    required int duration,
    required double calories,
    List<GPSPoint>? gpsPoints,
    String? notes,
    // 新增：室内运动子类型
    IndoorExerciseSubType? indoorSubType,
    // 新增：视频相关信息
    String? videoTitle,
    String? videoUrl,
  }) async {
    final exercise = ExerciseModel(
      id: _uuid.v4(),
      type: type,
      distance: distance,
      duration: duration,
      calories: calories,
      gpsPoints: gpsPoints,
      createdAt: DateTime.now(),
      notes: notes,
      indoorSubType: indoorSubType,
      videoTitle: videoTitle,
      videoUrl: videoUrl,
    );

    try {
      await _exerciseRepository.addExercise(exercise);
      _exercises.insert(0, exercise);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 添加室内运动记录（跟随视频）
  Future<void> addIndoorExercise({
    required IndoorExerciseSubType subType,
    required int duration,
    double distance = 0,
    double calories = 0,
    String? videoTitle,
    String? videoUrl,
    String? notes,
  }) async {
    await addExercise(
      type: ExerciseType.gym,
      distance: distance,
      duration: duration,
      calories: calories,
      notes: notes,
      indoorSubType: subType,
      videoTitle: videoTitle,
      videoUrl: videoUrl,
    );
  }

  /// 删除运动记录
  Future<void> deleteExercise(String id) async {
    try {
      await _exerciseRepository.deleteExercise(id);
      _exercises.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 获取单条运动记录
  Future<ExerciseModel?> getExerciseById(String id) async {
    return await _exerciseRepository.getExerciseById(id);
  }

  // ==================== 实时运动追踪 ====================

  /// 检查GPS/定位权限
  /// 高德定位权限由地图组件处理，这里简单返回true
  Future<bool> checkGpsPermission() async {
    _gpsEnabled = true;
    _gpsError = null;
    notifyListeners();
    return true;
  }

  /// 开始运动追踪（由ActiveWorkoutScreen通过高德定位回调添加轨迹点）
  void startTracking(ExerciseType type) {
    _isTracking = true;
    _trackingType = type;
    _trackingStartTime = DateTime.now();
    _trackingPoints = [];
    _gpsEnabled = true;
    notifyListeners();
  }

  /// 添加GPS点（从高德定位回调添加）
  void addTrackingPoint(GPSPoint point) {
    if (_isTracking) {
      _trackingPoints.add(point);
      notifyListeners();
    }
  }

  /// 结束运动追踪
  Future<ExerciseModel?> stopTracking({String? notes}) async {
    if (!_isTracking || _trackingType == null) return null;

    final distance = trackingDistance / 1000; // 转换为公里
    final duration = trackingDuration ~/ 60; // 转换为分钟
    final calories = trackingCalories;

    final exercise = ExerciseModel(
      id: _uuid.v4(),
      type: _trackingType!,
      distance: distance,
      duration: duration,
      calories: calories,
      gpsPoints: _trackingPoints,
      createdAt: _trackingStartTime ?? DateTime.now(),
      notes: notes,
    );

    try {
      await _exerciseRepository.addExercise(exercise);
      _exercises.insert(0, exercise);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }

    _isTracking = false;
    _trackingType = null;
    _trackingStartTime = null;
    _trackingPoints = [];

    return exercise;
  }

  /// 取消运动追踪
  void cancelTracking() {
    _isTracking = false;
    _trackingType = null;
    _trackingStartTime = null;
    _trackingPoints = [];
    notifyListeners();
  }
}
