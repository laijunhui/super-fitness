import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/main_shell.dart';
import 'presentation/screens/exercise/exercise_home_screen.dart';
import 'presentation/screens/exercise/exercise_detail_screen.dart';
import 'presentation/screens/exercise/add_exercise_screen.dart';
import 'presentation/screens/exercise/active_workout_screen.dart';
import 'presentation/screens/statistics/statistics_screen.dart';
import 'presentation/screens/body/body_metrics_screen.dart';
import 'presentation/screens/body/body_input_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/settings/goals_screen.dart';
import 'presentation/screens/settings/achievements_screen.dart';
import 'presentation/screens/tutorials/tutorials_screen.dart';
import 'presentation/screens/tutorials/video_player_screen.dart';
import 'core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';
import 'data/models/exercise_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SuperFitnessApp());
}

/// 健身应用根组件
class SuperFitnessApp extends StatelessWidget {
  const SuperFitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: getProviders(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'Super Fitness',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: appRouterWithShell(themeProvider.isDarkMode),
          );
        },
      ),
    );
  }
}

/// 带底部导航栏的路由配置
GoRouter appRouterWithShell(bool isDarkMode) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _ExerciseTab(),
            ),
          ),
          GoRoute(
            path: '/exercise',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _ExerciseTab(),
            ),
          ),
          GoRoute(
            path: '/tutorials',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _TutorialsTab(),
            ),
          ),
          GoRoute(
            path: '/body',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _BodyTab(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _SettingsTab(),
            ),
          ),
        ],
      ),
      // 非底部导航的页面
      GoRoute(
        path: '/exercise/active',
        builder: (context, state) => ActiveWorkoutScreen(
          exerciseType: state.extra as ExerciseType,
        ),
      ),
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
      GoRoute(
        path: '/exercise/:id',
        builder: (context, state) => ExerciseDetailScreen(
          exerciseId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/body/input',
        builder: (context, state) => const BodyInputScreen(),
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) => const GoalsScreen(),
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/tutorials/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VideoPlayerScreen(videoId: id);
        },
      ),
    ],
  );
}

// 底部导航Tab页面（会被ShellRoute包裹）
class _ExerciseTab extends StatelessWidget {
  const _ExerciseTab();

  @override
  Widget build(BuildContext context) => const ExerciseHomeScreen();
}

class _TutorialsTab extends StatelessWidget {
  const _TutorialsTab();

  @override
  Widget build(BuildContext context) => const TutorialsScreen();
}

class _BodyTab extends StatelessWidget {
  const _BodyTab();

  @override
  Widget build(BuildContext context) => const BodyMetricsScreen();
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) => const SettingsScreen();
}
