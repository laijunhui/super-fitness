import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/calorie_utils.dart';
import '../../../data/models/exercise_model.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/body_metrics_provider.dart';
import '../../providers/statistics_provider.dart';

/// 添加运动记录页（支持室内运动：跟随视频/自由）
class AddExerciseScreen extends StatefulWidget {
  final ExerciseType? initialType;
  final IndoorExerciseSubType? initialIndoorSubType;

  const AddExerciseScreen({
    super.key,
    this.initialType,
    this.initialIndoorSubType,
  });

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 自由类型控制器
  final _freeDurationController = TextEditingController();
  final _freeDistanceController = TextEditingController();
  final _freeCalorieController = TextEditingController();

  // 跟随视频类型控制器
  final _videoTitleController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _videoDurationController = TextEditingController();
  final _videoCalorieController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 如果指定了室内运动子类型，切换到对应tab
    if (widget.initialIndoorSubType != null) {
      if (widget.initialIndoorSubType == IndoorExerciseSubType.followVideo) {
        _tabController.index = 0;
      } else {
        _tabController.index = 1;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _freeDurationController.dispose();
    _freeDistanceController.dispose();
    _freeCalorieController.dispose();
    _videoTitleController.dispose();
    _videoUrlController.dispose();
    _videoDurationController.dispose();
    _videoCalorieController.dispose();
    super.dispose();
  }

  void _calculateFreeCalories() {
    if (_freeDurationController.text.isNotEmpty) {
      final duration = int.tryParse(_freeDurationController.text) ?? 0;
      final bodyMetrics = context.read<BodyMetricsProvider>().latestBodyMetrics;
      final weight = bodyMetrics?.weight ?? 70;

      final calories = CalorieUtils.estimateCalories(
        exerciseType: ExerciseType.gym,
        duration: duration,
        weight: weight,
      );
      _freeCalorieController.text = calories.toStringAsFixed(0);
    }
  }

  void _calculateVideoCalories() {
    if (_videoDurationController.text.isNotEmpty) {
      final duration = int.tryParse(_videoDurationController.text) ?? 0;
      final bodyMetrics = context.read<BodyMetricsProvider>().latestBodyMetrics;
      final weight = bodyMetrics?.weight ?? 70;

      // 使用中等强度估算（约 MET 5.5）
      final calories = CalorieUtils.estimateCalories(
        exerciseType: ExerciseType.gym,
        duration: duration,
        weight: weight,
      );
      _videoCalorieController.text = calories.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('添加运动'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '跟随视频'),
            Tab(text: '自由'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 跟随视频 Tab
          _buildFollowVideoTab(isDark),
          // 自由 Tab
          _buildFreeTab(isDark),
        ],
      ),
    );
  }

  /// 跟随视频 Tab
  Widget _buildFollowVideoTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 说明文字
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '填写视频信息来记录您的室内运动',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 视频标题
          _buildInputField(
            label: '视频标题',
            controller: _videoTitleController,
            isDark: isDark,
            hint: '请输入视频标题',
          ),
          const SizedBox(height: 16),

          // 视频链接
          _buildInputField(
            label: '视频链接',
            controller: _videoUrlController,
            isDark: isDark,
            hint: '请输入视频链接',
          ),
          const SizedBox(height: 16),

          // 视频播放时长
          _buildInputField(
            label: '视频播放时长（分钟）',
            controller: _videoDurationController,
            isDark: isDark,
            hint: '请输入播放时长',
            onChanged: (_) => _calculateVideoCalories(),
          ),
          const SizedBox(height: 16),

          // 卡路里（可选）
          _buildInputField(
            label: '消耗卡路里（kcal，选填）',
            controller: _videoCalorieController,
            isDark: isDark,
            hint: '自动估算或手动输入',
          ),
          const SizedBox(height: 32),

          // 保存按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveFollowVideoExercise,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('保存'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 自由 Tab
  Widget _buildFreeTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 说明文字
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '手动输入您的室内运动数据',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 运动时长
          _buildInputField(
            label: '运动时长（分钟）',
            controller: _freeDurationController,
            isDark: isDark,
            hint: '请输入运动时长',
            onChanged: (_) => _calculateFreeCalories(),
          ),
          const SizedBox(height: 16),

          // 运动距离（可选）
          _buildInputField(
            label: '运动距离（公里，选填）',
            controller: _freeDistanceController,
            isDark: isDark,
            hint: '如有请输入',
          ),
          const SizedBox(height: 16),

          // 卡路里（可选）
          _buildInputField(
            label: '消耗卡路里（kcal，选填）',
            controller: _freeCalorieController,
            isDark: isDark,
            hint: '自动估算或手动输入',
          ),
          const SizedBox(height: 32),

          // 保存按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveFreeExercise,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('保存'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    String? hint,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        NeumorphicContainer(
          isDark: isDark,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint ?? '请输入',
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _saveFollowVideoExercise() {
    final title = _videoTitleController.text.trim();
    final url = _videoUrlController.text.trim();
    final duration = int.tryParse(_videoDurationController.text) ?? 0;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入视频标题')),
      );
      return;
    }

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入视频链接')),
      );
      return;
    }

    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入视频播放时长')),
      );
      return;
    }

    final calories = double.tryParse(_videoCalorieController.text) ?? 0;

    context.read<ExerciseProvider>().addIndoorExercise(
      subType: IndoorExerciseSubType.followVideo,
      duration: duration,
      calories: calories,
      videoTitle: title,
      videoUrl: url,
    );

    context.read<StatisticsProvider>().loadStatistics();
    context.pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已记录：$title')),
    );
  }

  void _saveFreeExercise() {
    final duration = int.tryParse(_freeDurationController.text) ?? 0;

    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入运动时长')),
      );
      return;
    }

    final distance = double.tryParse(_freeDistanceController.text) ?? 0;
    final calories = double.tryParse(_freeCalorieController.text) ?? 0;

    context.read<ExerciseProvider>().addIndoorExercise(
      subType: IndoorExerciseSubType.free,
      duration: duration,
      distance: distance,
      calories: calories,
    );

    context.read<StatisticsProvider>().loadStatistics();
    context.pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已记录室内运动')),
    );
  }
}
