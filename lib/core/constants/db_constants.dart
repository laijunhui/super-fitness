/// 数据库相关常量
class DbConstants {
  DbConstants._();

  /// 数据库名称
  static const String databaseName = 'super_fitness.db';

  /// 数据库版本
  static const int databaseVersion = 2;

  /// 运动记录表名
  static const String exercisesTable = 'exercises';

  /// 身体指标表名
  static const String bodyMetricsTable = 'body_metrics';

  /// 用户设置表名
  static const String userSettingsTable = 'user_settings';
}
