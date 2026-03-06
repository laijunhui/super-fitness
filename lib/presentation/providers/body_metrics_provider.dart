import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/calorie_utils.dart';
import '../../core/utils/health_advice_utils.dart';
import '../../data/models/body_metrics_model.dart';
import '../../domain/entities/health_advice_entity.dart';
import '../../domain/repositories/body_metrics_repository.dart';

/// 身体指标状态管理
class BodyMetricsProvider extends ChangeNotifier {
  final BodyMetricsRepository _bodyMetricsRepository;
  final _uuid = const Uuid();

  List<BodyMetricsModel> _bodyMetricsList = [];
  BodyMetricsModel? _latestBodyMetrics;
  bool _isLoading = false;
  String? _error;

  // 健康建议相关
  HealthAdvice? _healthAdvice;
  EstimatedValue? _estimatedWaist;
  EstimatedValue? _estimatedChest;

  BodyMetricsProvider({required BodyMetricsRepository bodyMetricsRepository})
      : _bodyMetricsRepository = bodyMetricsRepository;

  // Getters
  List<BodyMetricsModel> get bodyMetricsList => _bodyMetricsList;
  BodyMetricsModel? get latestBodyMetrics => _latestBodyMetrics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 健康建议 Getters
  HealthAdvice? get healthAdvice => _healthAdvice;
  List<HealthEvaluation> get healthEvaluations => _healthAdvice?.evaluations ?? [];
  DietAdvice? get dietAdvice => _healthAdvice?.dietAdvice;
  ExerciseAdvice? get exerciseAdvice => _healthAdvice?.exerciseAdvice;
  bool get hasAbnormalIndicators => _healthAdvice?.hasAbnormalIndicators ?? false;
  EstimatedValue? get estimatedWaist => _estimatedWaist;
  EstimatedValue? get estimatedChest => _estimatedChest;

  /// 获取BMI
  double? get currentBMI => _latestBodyMetrics?.bmi;

  /// 获取BMR
  double? get currentBMR => _latestBodyMetrics?.bmr;

  /// 获取体脂率
  double? get currentBodyFat {
    if (_latestBodyMetrics == null) return null;
    final bmi = _latestBodyMetrics!.bmi;
    if (bmi == null) return null;
    return CalorieUtils.estimateBodyFat(
      bmi: bmi,
      age: _latestBodyMetrics!.age,
      gender: _latestBodyMetrics!.gender,
    );
  }

  /// 加载身体指标数据
  Future<void> loadBodyMetrics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bodyMetricsList = await _bodyMetricsRepository.getAllBodyMetrics();
      _latestBodyMetrics = await _bodyMetricsRepository.getLatestBodyMetrics();

      // 加载健康建议
      _loadHealthAdvice();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载健康建议
  void _loadHealthAdvice() {
    if (_latestBodyMetrics == null) {
      _healthAdvice = null;
      _estimatedWaist = null;
      _estimatedChest = null;
      return;
    }

    final bodyMetrics = _latestBodyMetrics!;

    // 生成健康建议
    _healthAdvice = HealthAdviceUtils.generateHealthAdvice(bodyMetrics);

    // 获取腰围估算值
    if (bodyMetrics.waist != null && bodyMetrics.waist! > 0) {
      _estimatedWaist = EstimatedValue(value: bodyMetrics.waist!, isEstimated: false);
    } else {
      _estimatedWaist = EstimatedValue(
        value: bodyMetrics.height * (bodyMetrics.gender == Gender.male ? 0.42 : 0.38),
        isEstimated: true,
        source: '*系统生成',
      );
    }

    // 获取胸围估算值
    _estimatedChest = bodyMetrics.chest != null && bodyMetrics.chest! > 0
        ? EstimatedValue(value: bodyMetrics.chest!, isEstimated: false)
        : EstimatedValue(
            value: bodyMetrics.height * (bodyMetrics.gender == Gender.male ? 0.53 : 0.49),
            isEstimated: true,
            source: '*系统生成',
          );
  }

  /// 保存身体指标
  Future<void> saveBodyMetrics({
    required double height,
    required double weight,
    double? waist,
    double? chest,
    required int age,
    required Gender gender,
  }) async {
    // 计算BMI和BMR
    final bmi = CalorieUtils.calculateBMI(
      weight: weight,
      height: height,
    );

    final bmr = CalorieUtils.calculateBMR(
      weight: weight,
      height: height,
      age: age,
      gender: gender,
    );

    final bodyMetrics = BodyMetricsModel(
      id: _uuid.v4(),
      height: height,
      weight: weight,
      waist: waist,
      chest: chest,
      age: age,
      gender: gender,
      bmi: bmi,
      bmr: bmr,
      createdAt: DateTime.now(),
    );

    try {
      await _bodyMetricsRepository.addBodyMetrics(bodyMetrics);
      _bodyMetricsList.insert(0, bodyMetrics);
      _latestBodyMetrics = bodyMetrics;

      // 更新健康建议
      _loadHealthAdvice();

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 删除身体指标记录
  Future<void> deleteBodyMetrics(String id) async {
    try {
      await _bodyMetricsRepository.deleteBodyMetrics(id);
      _bodyMetricsList.removeWhere((m) => m.id == id);
      if (_latestBodyMetrics?.id == id) {
        _latestBodyMetrics = _bodyMetricsList.isNotEmpty
            ? _bodyMetricsList.first
            : null;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 预览计算结果（不保存）
  Map<String, double> previewCalculation({
    required double height,
    required double weight,
    required int age,
    required Gender gender,
  }) {
    final bmi = CalorieUtils.calculateBMI(
      weight: weight,
      height: height,
    );
    final bmr = CalorieUtils.calculateBMR(
      weight: weight,
      height: height,
      age: age,
      gender: gender,
    );
    final bodyFat = CalorieUtils.estimateBodyFat(
      bmi: bmi,
      age: age,
      gender: gender,
    );

    return {
      'bmi': bmi,
      'bmr': bmr,
      'bodyFat': bodyFat,
    };
  }
}
