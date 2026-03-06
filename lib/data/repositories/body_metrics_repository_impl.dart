import '../../core/constants/db_constants.dart';
import '../../domain/repositories/body_metrics_repository.dart';
import '../database/database_helper.dart';
import '../models/body_metrics_model.dart';

/// 身体指标仓储实现
class BodyMetricsRepositoryImpl implements BodyMetricsRepository {
  final DatabaseHelper _databaseHelper;

  BodyMetricsRepositoryImpl({required DatabaseHelper databaseHelper})
      : _databaseHelper = databaseHelper;

  @override
  Future<List<BodyMetricsModel>> getAllBodyMetrics() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DbConstants.bodyMetricsTable,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => BodyMetricsModel.fromMap(map)).toList();
  }

  @override
  Future<BodyMetricsModel?> getLatestBodyMetrics() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DbConstants.bodyMetricsTable,
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BodyMetricsModel.fromMap(maps.first);
  }

  @override
  Future<BodyMetricsModel?> getBodyMetricsById(String id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DbConstants.bodyMetricsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return BodyMetricsModel.fromMap(maps.first);
  }

  @override
  Future<void> addBodyMetrics(BodyMetricsModel bodyMetrics) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DbConstants.bodyMetricsTable,
      bodyMetrics.toMap(),
    );
  }

  @override
  Future<void> updateBodyMetrics(BodyMetricsModel bodyMetrics) async {
    final db = await _databaseHelper.database;
    await db.update(
      DbConstants.bodyMetricsTable,
      bodyMetrics.toMap(),
      where: 'id = ?',
      whereArgs: [bodyMetrics.id],
    );
  }

  @override
  Future<void> deleteBodyMetrics(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      DbConstants.bodyMetricsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
