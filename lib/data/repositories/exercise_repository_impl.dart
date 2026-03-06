import '../../core/constants/db_constants.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../domain/repositories/exercise_repository.dart';
import '../database/database_helper.dart';
import '../models/exercise_model.dart';

/// 运动记录仓储实现
class ExerciseRepositoryImpl implements ExerciseRepository {
  final DatabaseHelper _databaseHelper;

  ExerciseRepositoryImpl({required DatabaseHelper databaseHelper})
      : _databaseHelper = databaseHelper;

  @override
  Future<List<ExerciseModel>> getAllExercises() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DbConstants.exercisesTable,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => ExerciseModel.fromMap(map)).toList();
  }

  @override
  Future<List<ExerciseModel>> getExercisesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DbConstants.exercisesTable,
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => ExerciseModel.fromMap(map)).toList();
  }

  @override
  Future<ExerciseModel?> getExerciseById(String id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DbConstants.exercisesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ExerciseModel.fromMap(maps.first);
  }

  @override
  Future<void> addExercise(ExerciseModel exercise) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DbConstants.exercisesTable,
      exercise.toMap(),
    );
  }

  @override
  Future<void> updateExercise(ExerciseModel exercise) async {
    final db = await _databaseHelper.database;
    await db.update(
      DbConstants.exercisesTable,
      exercise.toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  @override
  Future<void> deleteExercise(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      DbConstants.exercisesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<ExerciseModel>> getTodayExercises() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59);
    return getExercisesByDateRange(start, end);
  }

  @override
  Future<List<ExerciseModel>> getWeekExercises() async {
    return getExercisesByDateRange(
      app_date_utils.DateUtils.getWeekStart(),
      app_date_utils.DateUtils.getWeekEnd(),
    );
  }

  @override
  Future<List<ExerciseModel>> getMonthExercises() async {
    return getExercisesByDateRange(
      app_date_utils.DateUtils.getMonthStart(),
      app_date_utils.DateUtils.getMonthEnd(),
    );
  }
}
