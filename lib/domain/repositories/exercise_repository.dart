import '../../data/models/exercise_model.dart';

/// 运动记录仓储接口
abstract class ExerciseRepository {
  /// 获取所有运动记录
  Future<List<ExerciseModel>> getAllExercises();

  /// 获取运动记录（按日期范围）
  Future<List<ExerciseModel>> getExercisesByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// 获取单条运动记录
  Future<ExerciseModel?> getExerciseById(String id);

  /// 添加运动记录
  Future<void> addExercise(ExerciseModel exercise);

  /// 更新运动记录
  Future<void> updateExercise(ExerciseModel exercise);

  /// 删除运动记录
  Future<void> deleteExercise(String id);

  /// 获取今日运动记录
  Future<List<ExerciseModel>> getTodayExercises();

  /// 获取本周运动记录
  Future<List<ExerciseModel>> getWeekExercises();

  /// 获取本月运动记录
  Future<List<ExerciseModel>> getMonthExercises();
}
