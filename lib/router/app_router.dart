import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../data/models/exercise_model.dart';
import '../presentation/screens/exercise/exercise_home_screen.dart';
import '../presentation/screens/exercise/exercise_detail_screen.dart';
import '../presentation/screens/exercise/add_exercise_screen.dart';
import '../presentation/screens/exercise/active_workout_screen.dart';
import '../presentation/screens/statistics/statistics_screen.dart';
import '../presentation/screens/body/body_metrics_screen.dart';
import '../presentation/screens/body/body_input_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/settings/goals_screen.dart';
import '../presentation/screens/settings/achievements_screen.dart';
import '../presentation/screens/tutorials/tutorials_screen.dart';
import '../presentation/screens/tutorials/video_player_screen.dart';

/// 应用路由配置
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // 运动首页（整合版）
    GoRoute(
      path: '/',
      builder: (context, state) => const ExerciseHomeScreen(),
    ),
    // 运动记录列表
    GoRoute(
      path: '/exercise',
      builder: (context, state) => const ExerciseHomeScreen(),
    ),
    // 运动详情
    GoRoute(
      path: '/exercise/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ExerciseDetailScreen(exerciseId: id);
      },
    ),
    // 添加运动
    GoRoute(
      path: '/exercise/add',
      builder: (context, state) {
        final extra = state.extra;
        ExerciseType? type;
        IndoorExerciseSubType? indoorSubType;

        if (extra is ExerciseType) {
          type = extra;
        } else if (extra is Map<String, dynamic>) {
          final typeVal = extra['type'];
          final indoorSubTypeVal = extra['indoorSubType'];
          if (typeVal is ExerciseType) {
            type = typeVal;
          }
          if (indoorSubTypeVal is IndoorExerciseSubType) {
            indoorSubType = indoorSubTypeVal;
          }
        }

        return AddExerciseScreen(
          initialType: type,
          initialIndoorSubType: indoorSubType,
        );
      },
    ),
    // 实时运动追踪
    GoRoute(
      path: '/exercise/active',
      builder: (context, state) {
        final type = state.extra as ExerciseType;
        return ActiveWorkoutScreen(exerciseType: type);
      },
    ),
    // 数据统计
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsScreen(),
    ),
    // 身体指标
    GoRoute(
      path: '/body',
      builder: (context, state) => const BodyMetricsScreen(),
    ),
    // 身体数据录入
    GoRoute(
      path: '/body/input',
      builder: (context, state) => const BodyInputScreen(),
    ),
    // 设置
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    // 运动目标与提醒
    GoRoute(
      path: '/goals',
      builder: (context, state) => const GoalsScreen(),
    ),
    // 成就
    GoRoute(
      path: '/achievements',
      builder: (context, state) => const AchievementsScreen(),
    ),
    // 教程列表
    GoRoute(
      path: '/tutorials',
      builder: (context, state) => const TutorialsScreen(),
    ),
    // 视频播放
    GoRoute(
      path: '/tutorials/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return VideoPlayerScreen(videoId: id);
      },
    ),
  ],
);
