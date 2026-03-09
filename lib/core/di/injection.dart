import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../../data/database/database_helper.dart';
import '../../data/repositories/exercise_repository_impl.dart';
import '../../data/repositories/body_metrics_repository_impl.dart';
import '../../data/repositories/tutorial_repository_impl.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../../domain/repositories/body_metrics_repository.dart';
import '../../domain/repositories/tutorial_repository.dart';
import '../../presentation/providers/exercise_provider.dart';
import '../../presentation/providers/statistics_provider.dart';
import '../../presentation/providers/body_metrics_provider.dart';
import '../../presentation/providers/theme_provider.dart';
import '../../presentation/providers/map_provider.dart';
import '../../presentation/providers/trend_provider.dart';
import '../../presentation/providers/goal_provider.dart';
import '../../presentation/providers/achievement_provider.dart';
import '../../presentation/providers/tutorial_provider.dart';

/// 获取所有Provider配置
List<SingleChildWidget> getProviders() {
  return [
    // 数据库
    Provider<DatabaseHelper>(
      create: (_) => DatabaseHelper(),
    ),

    // 仓储接口
    Provider<ExerciseRepository>(
      create: (context) => ExerciseRepositoryImpl(
        databaseHelper: context.read<DatabaseHelper>(),
      ),
    ),
    Provider<BodyMetricsRepository>(
      create: (context) => BodyMetricsRepositoryImpl(
        databaseHelper: context.read<DatabaseHelper>(),
      ),
    ),
    Provider<TutorialRepository>(
      create: (_) => TutorialRepositoryImpl(),
    ),

    // Providers (状态管理)
    ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(),
    ),
    ChangeNotifierProvider<ExerciseProvider>(
      create: (context) => ExerciseProvider(
        exerciseRepository: context.read<ExerciseRepository>(),
      ),
    ),
    ChangeNotifierProvider<StatisticsProvider>(
      create: (context) => StatisticsProvider(
        exerciseRepository: context.read<ExerciseRepository>(),
      ),
    ),
    ChangeNotifierProvider<BodyMetricsProvider>(
      create: (context) => BodyMetricsProvider(
        bodyMetricsRepository: context.read<BodyMetricsRepository>(),
      ),
    ),
    ChangeNotifierProvider<MapProvider>(
      create: (_) => MapProvider(),
    ),
    ChangeNotifierProvider<TrendProvider>(
      create: (context) => TrendProvider(
        exerciseRepository: context.read<ExerciseRepository>(),
      ),
    ),
    ChangeNotifierProxyProvider<ExerciseRepository, GoalProvider>(
      create: (context) => GoalProvider(
        exerciseRepository: context.read<ExerciseRepository>(),
      ),
      update: (context, repository, previous) =>
          previous ?? GoalProvider(exerciseRepository: repository),
    ),
    ChangeNotifierProxyProvider<ExerciseRepository, AchievementProvider>(
      create: (context) => AchievementProvider(
        exerciseRepository: context.read<ExerciseRepository>(),
      ),
      update: (context, repository, previous) =>
          previous ?? AchievementProvider(exerciseRepository: repository),
    ),
    ChangeNotifierProvider<TutorialProvider>(
      create: (context) => TutorialProvider(
        repository: context.read<TutorialRepository>(),
      ),
    ),
  ];
}
