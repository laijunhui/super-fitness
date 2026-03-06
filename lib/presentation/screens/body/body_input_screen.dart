import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/body_metrics_provider.dart';
import '../../providers/theme_provider.dart';

/// 身体数据录入页
class BodyInputScreen extends StatefulWidget {
  const BodyInputScreen({super.key});

  @override
  State<BodyInputScreen> createState() => _BodyInputScreenState();
}

class _BodyInputScreenState extends State<BodyInputScreen> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _waistController = TextEditingController();
  final _chestController = TextEditingController();
  final _ageController = TextEditingController();

  Gender _selectedGender = Gender.male;
  Map<String, double>? _previewResults;

  @override
  void initState() {
    super.initState();
    final latest = context.read<BodyMetricsProvider>().latestBodyMetrics;
    if (latest != null) {
      _heightController.text = latest.height.toString();
      _weightController.text = latest.weight.toString();
      _ageController.text = latest.age.toString();
      _selectedGender = latest.gender;
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _waistController.dispose();
    _chestController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    final age = int.tryParse(_ageController.text);

    if (height != null && weight != null && age != null) {
      setState(() {
        _previewResults = context.read<BodyMetricsProvider>().previewCalculation(
          height: height,
          weight: weight,
          age: age,
          gender: _selectedGender,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('录入身体数据'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 性别选择
            Text(
              '性别',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: Gender.values.map((gender) {
                final isSelected = _selectedGender == gender;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedGender = gender;
                      _updatePreview();
                    }),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          gender.displayName,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 输入字段
            _buildInputField(
              label: '身高（cm）',
              controller: _heightController,
              isDark: isDark,
              onChanged: (_) => _updatePreview(),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: '体重（kg）',
              controller: _weightController,
              isDark: isDark,
              onChanged: (_) => _updatePreview(),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: '年龄',
              controller: _ageController,
              isDark: isDark,
              onChanged: (_) => _updatePreview(),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: '腰围（cm，可选）',
              controller: _waistController,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: '胸围（cm，可选）',
              controller: _chestController,
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // 预览结果
            if (_previewResults != null) ...[
              Text(
                '计算结果预览',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCardPreview(
                      label: 'BMI',
                      value: _previewResults!['bmi']?.toStringAsFixed(1) ?? '-',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCardPreview(
                      label: '基础代谢',
                      value: _previewResults!['bmr']?.toStringAsFixed(0) ?? '-',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCardPreview(
                      label: '体脂率',
                      value: '${_previewResults!['bodyFat']?.toStringAsFixed(1) ?? '-'}%',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
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

  void _save() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    final age = int.tryParse(_ageController.text);

    if (height == null || weight == null || age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写完整信息')),
      );
      return;
    }

    final waist = double.tryParse(_waistController.text);
    final chest = double.tryParse(_chestController.text);

    context.read<BodyMetricsProvider>().saveBodyMetrics(
      height: height,
      weight: weight,
      waist: waist,
      chest: chest,
      age: age,
      gender: _selectedGender,
    );

    context.pop();
  }
}

class StatCardPreview extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const StatCardPreview({
    super.key,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      isDark: isDark,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
