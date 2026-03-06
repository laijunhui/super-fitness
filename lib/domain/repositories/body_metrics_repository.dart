import '../../data/models/body_metrics_model.dart';

/// 身体指标仓储接口
abstract class BodyMetricsRepository {
  /// 获取所有身体指标记录
  Future<List<BodyMetricsModel>> getAllBodyMetrics();

  /// 获取最新身体指标
  Future<BodyMetricsModel?> getLatestBodyMetrics();

  /// 获取单条身体指标
  Future<BodyMetricsModel?> getBodyMetricsById(String id);

  /// 添加身体指标
  Future<void> addBodyMetrics(BodyMetricsModel bodyMetrics);

  /// 更新身体指标
  Future<void> updateBodyMetrics(BodyMetricsModel bodyMetrics);

  /// 删除身体指标
  Future<void> deleteBodyMetrics(String id);
}
