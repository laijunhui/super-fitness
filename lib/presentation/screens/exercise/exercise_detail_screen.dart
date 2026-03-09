import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/exercise_model.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/exercise_map_detail.dart';

/// 运动详情页
class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseId;

  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  ExerciseModel? _exercise;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercise();
  }

  Future<void> _loadExercise() async {
    final provider = context.read<ExerciseProvider>();
    final exercise = await provider.getExerciseById(widget.exerciseId);
    setState(() {
      _exercise = exercise;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('运动详情'),
        actions: [
          if (_exercise != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showDeleteDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exercise == null
              ? const Center(child: Text('未找到运动记录'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final hasGpsData = _exercise!.gpsPoints != null && _exercise!.gpsPoints!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Text(
                _exercise!.type.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Text(
                _exercise!.type.displayName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 统计数据
          _buildStatCard(
            isDark: isDark,
            children: [
              _buildStatRow('开始时间', _formatDateTime(_exercise!.createdAt), isDark),
              _buildStatRow('时长', '${_exercise!.duration}分钟', isDark),
              _buildStatRow('距离', '${_exercise!.distance.toStringAsFixed(2)} km', isDark),
              _buildStatRow('卡路里', '${_exercise!.calories.toStringAsFixed(0)} kcal', isDark),
              if (hasGpsData)
                _buildStatRow('轨迹点数', '${_exercise!.gpsPoints!.length}', isDark),
            ],
          ),
          const SizedBox(height: 24),

          // 地图区域
          if (hasGpsData) ...[
            Text(
              '运动轨迹',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: ExerciseMapDetail(
                exercise: _exercise!,
                isDark: isDark,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({required bool isDark, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildStatRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定要删除这条运动记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<ExerciseProvider>().deleteExercise(widget.exerciseId);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
