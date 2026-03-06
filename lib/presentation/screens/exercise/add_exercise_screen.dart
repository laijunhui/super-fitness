import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/calorie_utils.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/body_metrics_provider.dart';
import '../../providers/statistics_provider.dart';

/// 添加运动记录页
class AddExerciseScreen extends StatefulWidget {
  final ExerciseType? initialType;

  const AddExerciseScreen({super.key, this.initialType});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  ExerciseType? _selectedType;
  final _distanceController = TextEditingController();
  final _durationController = TextEditingController();
  final _calorieController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _durationController.dispose();
    _calorieController.dispose();
    super.dispose();
  }

  void _calculateCalories() {
    if (_selectedType != null && _durationController.text.isNotEmpty) {
      final duration = int.tryParse(_durationController.text) ?? 0;
      final bodyMetrics = context.read<BodyMetricsProvider>().latestBodyMetrics;
      final weight = bodyMetrics?.weight ?? 70;

      final calories = CalorieUtils.estimateCalories(
        exerciseType: _selectedType!,
        duration: duration,
        weight: weight,
      );
      _calorieController.text = calories.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('添加运动'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 运动类型选择
            Text(
              '运动类型',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: ExerciseType.values.map((type) {
                final isSelected = _selectedType == type;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: NeumorphicContainer(
                    isDark: isDark,
                    isPressed: isSelected,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(type.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(type.displayName),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 输入字段
            _buildInputField(
              label: '运动时长（分钟）',
              controller: _durationController,
              isDark: isDark,
              onChanged: (_) => _calculateCalories(),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: '运动距离（公里）',
              controller: _distanceController,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: '消耗卡路里（kcal）',
              controller: _calorieController,
              isDark: isDark,
            ),
            const SizedBox(height: 32),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveExercise,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('保存'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
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
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '请输入',
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _saveExercise() {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择运动类型')),
      );
      return;
    }

    final duration = int.tryParse(_durationController.text) ?? 0;
    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入运动时长')),
      );
      return;
    }

    final distance = double.tryParse(_distanceController.text) ?? 0;
    final calories = double.tryParse(_calorieController.text) ?? 0;

    context.read<ExerciseProvider>().addExercise(
      type: _selectedType!,
      distance: distance,
      duration: duration,
      calories: calories,
    );

    context.read<StatisticsProvider>().loadStatistics();
    context.pop();
  }
}
