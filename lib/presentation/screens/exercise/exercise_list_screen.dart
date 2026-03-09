import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/exercise_model.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../widgets/exercise_map_card.dart';

/// 运动记录列表页
class ExerciseListScreen extends StatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  // 默认筛选条件：最近7天 + 跑步
  FilterPeriod _selectedPeriod = FilterPeriod.week;
  ExerciseType? _selectedExerciseType = ExerciseType.running;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExerciseProvider>().loadExercises();
      context.read<StatisticsProvider>().loadStatistics();
    });
  }

  /// 根据筛选条件过滤运动记录
  List<ExerciseModel> _filterExercises(List<ExerciseModel> exercises) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: _selectedPeriod.days));

    return exercises.where((exercise) {
      // 时间筛选
      if (exercise.createdAt.isBefore(startDate)) {
        return false;
      }
      // 运动类型筛选
      if (_selectedExerciseType != null && exercise.type != _selectedExerciseType) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final exerciseProvider = context.watch<ExerciseProvider>();
    final isDark = themeProvider.isDarkMode;

    // 应用筛选条件
    final filteredExercises = _filterExercises(exerciseProvider.exercises);

    return Scaffold(
      appBar: AppBar(
        title: const Text('运动记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/exercise/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(isDark),
          Expanded(
            child: exerciseProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredExercises.isEmpty
                    ? _buildEmptyState(isDark)
                    : _buildExerciseList(filteredExercises, isDark),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/exercise/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建筛选栏
  Widget _buildFilterBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground,
      ),
      child: Row(
        children: [
          // 时间筛选
          Expanded(
            child: DropdownButtonFormField<FilterPeriod>(
              value: _selectedPeriod,
              decoration: InputDecoration(
                labelText: '时间',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: FilterPeriod.values.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(period.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPeriod = value;
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          // 运动类型筛选
          Expanded(
            child: DropdownButtonFormField<ExerciseType?>(
              value: _selectedExerciseType,
              decoration: InputDecoration(
                labelText: '类型',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('全部'),
                ),
                ...ExerciseType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text('${type.icon} ${type.displayName}'),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedExerciseType = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_run_outlined,
            size: 80,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无运动记录',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮开始记录运动',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(List<ExerciseModel> exercises, bool isDark) {
    return RefreshIndicator(
      onRefresh: () => context.read<ExerciseProvider>().loadExercises(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return ExerciseMapCard(
            exercise: exercise,
            isDark: isDark,
            onTap: () => context.push('/exercise/${exercise.id}'),
          );
        },
      ),
    );
  }
}
