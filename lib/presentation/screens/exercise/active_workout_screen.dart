import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../providers/exercise_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../../core/widgets/neumorphic_container.dart';

/// 实时运动追踪页
class ActiveWorkoutScreen extends StatefulWidget {
  final ExerciseType exerciseType;

  const ActiveWorkoutScreen({super.key, required this.exerciseType});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  Timer? _timer;
  bool _isPaused = false;
  bool _useManualMode = false;
  final _manualDistanceController = TextEditingController();
  final _manualDurationController = TextEditingController();
  final _manualCalorieController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _manualDistanceController.dispose();
    _manualDurationController.dispose();
    _manualCalorieController.dispose();
    super.dispose();
  }

  void _initTracking() {
    // 直接初始化，不等待任何异步操作
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTracking();
    });
  }

  void _startTracking() {
    if (!mounted) return;

    try {
      final provider = context.read<ExerciseProvider>();
      provider.startTracking(widget.exerciseType);
      // 异步检查GPS，不阻塞UI
      provider.checkGpsPermission().then((result) {
        // GPS检查完成
      }).catchError((e) {
        // GPS检查错误
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } catch (e) {
      debugPrint('Error starting tracking: $e');
    }
  }

  void _pauseTracking() {
    setState(() => _isPaused = true);
    _timer?.cancel();
  }

  void _resumeTracking() {
    setState(() => _isPaused = false);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  /// 切换到手动模式
  void _toggleManualMode() {
    setState(() {
      _useManualMode = !_useManualMode;
      if (_useManualMode) {
        _timer?.cancel();
      } else {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  /// 保存手动输入的运动记录
  void _saveManualExercise() {
    final duration = int.tryParse(_manualDurationController.text) ?? 0;
    final distance = double.tryParse(_manualDistanceController.text) ?? 0;
    final calories = double.tryParse(_manualCalorieController.text) ?? 0;

    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入运动时长')),
      );
      return;
    }

    context.read<ExerciseProvider>().addExercise(
      type: widget.exerciseType,
      distance: distance,
      duration: duration,
      calories: calories,
    );

    context.read<StatisticsProvider>().loadStatistics();
    context.pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.exerciseType.displayName}记录已保存')),
    );
  }

  Future<void> _stopTracking() async {
    _timer?.cancel();
    try {
      await context.read<ExerciseProvider>().stopTracking();
      await context.read<ExerciseProvider>().loadExercises();
      if (mounted) {
        context.read<StatisticsProvider>().loadStatistics();
        context.pop();
      }
    } catch (e) {
      debugPrint('Error stopping tracking: $e');
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final exerciseProvider = context.watch<ExerciseProvider>();
    final isDark = themeProvider.isDarkMode;

    // 如果是手动模式，显示手动输入UI
    if (_useManualMode) {
      return _buildManualModeUI(isDark);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseType.displayName),
        actions: [
          TextButton(
            onPressed: _toggleManualMode,
            child: const Text('手动'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 运动类型图标
            Text(
              widget.exerciseType.icon,
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 32),

            // 计时器
            Text(
              app_date_utils.DateUtils.formatTimer(exerciseProvider.trackingDuration),
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 48),

            // GPS状态
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: exerciseProvider.gpsEnabled
                    ? Colors.green.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    exerciseProvider.gpsEnabled ? Icons.gps_fixed : Icons.gps_off,
                    size: 16,
                    color: exerciseProvider.gpsEnabled ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    exerciseProvider.gpsEnabled
                        ? 'GPS追踪中 (${exerciseProvider.trackingPoints.length}点)'
                        : 'GPS未开启 - 请在模拟器中设置位置',
                    style: TextStyle(
                      color: exerciseProvider.gpsEnabled ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (exerciseProvider.gpsError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  exerciseProvider.gpsError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),

            // 统计卡片
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: '距离',
                    value: (exerciseProvider.trackingDistance / 1000).toStringAsFixed(2),
                    unit: 'km',
                    icon: Icons.straighten_outlined,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: '卡路里',
                    value: exerciseProvider.trackingCalories.toStringAsFixed(0),
                    unit: 'kcal',
                    icon: Icons.local_fire_department_outlined,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const Spacer(),

            // 控制按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: 'cancel',
                  onPressed: () {
                    exerciseProvider.cancelTracking();
                    context.pop();
                  },
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.close),
                ),
                FloatingActionButton.large(
                  heroTag: 'pause',
                  onPressed: _isPaused ? _resumeTracking : _pauseTracking,
                  backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  child: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                ),
                FloatingActionButton(
                  heroTag: 'stop',
                  onPressed: _stopTracking,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.check),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 手动输入模式UI
  Widget _buildManualModeUI(bool isDark) {
    return Scaffold(
      appBar: AppBar(
        title: Text('手动记录 - ${widget.exerciseType.displayName}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _toggleManualMode,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 说明
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '手动模式：直接输入运动数据，不依赖GPS定位',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 运动类型显示
            Center(
              child: Column(
                children: [
                  Text(
                    widget.exerciseType.icon,
                    style: const TextStyle(fontSize: 60),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.exerciseType.displayName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 输入字段
            _buildInputField(
              label: '运动时长（分钟）',
              controller: _manualDurationController,
              isDark: isDark,
              hint: '请输入运动时长',
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: '运动距离（公里）',
              controller: _manualDistanceController,
              isDark: isDark,
              hint: '请输入运动距离（可选）',
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: '消耗卡路里（kcal）',
              controller: _manualCalorieController,
              isDark: isDark,
              hint: '请输入消耗卡路里（可选）',
            ),
            const SizedBox(height: 32),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveManualExercise,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('保存运动记录'),
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
    String? hint,
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
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
            ),
          ),
        ),
      ],
    );
  }
}
