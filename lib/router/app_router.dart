import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/exercise/exercise_list_screen.dart';
import '../presentation/screens/exercise/exercise_detail_screen.dart';
import '../presentation/screens/exercise/add_exercise_screen.dart';
import '../presentation/screens/exercise/active_workout_screen.dart';
import '../presentation/screens/statistics/statistics_screen.dart';
import '../presentation/screens/body/body_metrics_screen.dart';
import '../presentation/screens/body/body_input_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../core/constants/app_constants.dart';

/// 应用路由配置
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // 首页（统计）
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    // 运动记录列表
    GoRoute(
      path: '/exercise',
      builder: (context, state) => const ExerciseListScreen(),
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
        final type = state.extra as ExerciseType?;
        return AddExerciseScreen(initialType: type);
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
  ],
);
