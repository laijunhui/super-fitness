import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/goal_model.dart';
import '../../providers/goal_provider.dart';
import '../../providers/theme_provider.dart';

/// 运动目标与提醒页
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoalProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final goalProvider = context.watch<GoalProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('运动目标与提醒'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前目标
            Text(
              '当前目标',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildGoalCard(goalProvider, isDark),
            const SizedBox(height: 24),

            // 提醒列表
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '运动提醒',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddReminderDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('添加'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRemindersList(goalProvider, isDark),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context),
        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGoalCard(GoalProvider provider, bool isDark) {
    final goal = provider.currentGoal;

    if (goal == null) {
      return NeumorphicContainer(
        isDark: isDark,
        child: Container(
          padding: const EdgeInsets.all(24),
          width: double.infinity,
          child: Column(
            children: [
              Icon(
                Icons.flag_outlined,
                size: 48,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                '暂无目标',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '点击下方按钮设置运动目标',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<double>(
      future: provider.calculateProgressAsync(),
      builder: (context, snapshot) {
        final progress = snapshot.data ?? 0.0;
        return NeumorphicContainer(
          isDark: isDark,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      goal.type.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.type.displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            '目标: ${goal.goalType.displayName}',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      onPressed: () => provider.clearGoal(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '目标值: ${goal.targetValue} ${goal.goalType.unit}',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: isDark ? AppColors.darkShadowDark : AppColors.lightShadowDark,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRemindersList(GoalProvider provider, bool isDark) {
    final reminders = provider.reminders;

    if (reminders.isEmpty) {
      return NeumorphicContainer(
        isDark: isDark,
        child: Container(
          padding: const EdgeInsets.all(24),
          width: double.infinity,
          child: Column(
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 48,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                '暂无提醒',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: reminders.map((reminder) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NeumorphicContainer(
            isDark: isDark,
            child: ListTile(
              leading: Icon(
                Icons.notifications,
                color: reminder.isEnabled
                    ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              title: Text(
                '${reminder.timeString} - ${reminder.weekdaysString}',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              subtitle: Text(
                reminder.label ?? '运动提醒',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              trailing: Switch(
                value: reminder.isEnabled,
                onChanged: (_) => provider.toggleReminder(reminder.id),
                activeColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    ExerciseType selectedType = ExerciseType.running;
    GoalType selectedGoalType = GoalType.distance;
    final targetController = TextEditingController(text: '5');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('设置运动目标'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('运动类型'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ExerciseType.values.map((type) {
                      return ChoiceChip(
                        label: Text('${type.icon} ${type.displayName}'),
                        selected: selectedType == type,
                        onSelected: (_) => setState(() => selectedType = type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('目标类型'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: GoalType.values.map((type) {
                      return ChoiceChip(
                        label: Text(type.displayName),
                        selected: selectedGoalType == type,
                        onSelected: (_) => setState(() => selectedGoalType = type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '目标值',
                      suffixText: selectedGoalType.unit,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  final target = double.tryParse(targetController.text) ?? 0;
                  if (target > 0) {
                    context.read<GoalProvider>().setGoal(
                      type: selectedType,
                      goalType: selectedGoalType,
                      targetValue: target,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    int selectedHour = 8;
    int selectedMinute = 0;
    final Set<int> selectedWeekdays = {1, 2, 3, 4, 5}; // 默认工作日

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('添加提醒'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('时间'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int>(
                          value: selectedHour,
                          isExpanded: true,
                          items: List.generate(24, (i) => i).map((hour) {
                            return DropdownMenuItem(
                              value: hour,
                              child: Text(hour.toString().padLeft(2, '0')),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => selectedHour = value ?? 8),
                        ),
                      ),
                      const Text(' : '),
                      Expanded(
                        child: DropdownButton<int>(
                          value: selectedMinute,
                          isExpanded: true,
                          items: List.generate(60, (i) => i).map((minute) {
                            return DropdownMenuItem(
                              value: minute,
                              child: Text(minute.toString().padLeft(2, '0')),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => selectedMinute = value ?? 0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('重复'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (int i = 1; i <= 7; i++)
                        FilterChip(
                          label: Text(['周一', '周二', '周三', '周四', '周五', '周六', '周日'][i - 1]),
                          selected: selectedWeekdays.contains(i),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedWeekdays.add(i);
                              } else {
                                selectedWeekdays.remove(i);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: selectedWeekdays.isEmpty
                    ? null
                    : () {
                        context.read<GoalProvider>().addReminder(
                          hour: selectedHour,
                          minute: selectedMinute,
                          weekdays: selectedWeekdays.toList(),
                          label: '该运动了！',
                        );
                        Navigator.pop(context);
                      },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }
}
