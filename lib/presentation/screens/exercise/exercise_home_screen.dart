import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../data/models/exercise_model.dart';
import '../../../data/models/tutorial_video.dart';
import '../../providers/statistics_provider.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/tutorial_provider.dart';

/// 运动首页（整合版）- 包含统计概览 + 运动记录
class ExerciseHomeScreen extends StatefulWidget {
  const ExerciseHomeScreen({super.key});

  @override
  State<ExerciseHomeScreen> createState() => _ExerciseHomeScreenState();
}

class _ExerciseHomeScreenState extends State<ExerciseHomeScreen> {
  List<TutorialVideo> _frequentVideos = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsProvider>().loadStatistics();
      context.read<ExerciseProvider>().loadExercises();
      // 直接获取本地常播放的视频，不请求B站API
      _loadFrequentVideos();
    });
  }

  /// 加载本地常播放的视频（完全使用本地缓存，不请求API）
  Future<void> _loadFrequentVideos() async {
    final tutorialProvider = context.read<TutorialProvider>();
    // 从本地缓存获取常播放的视频（如果没有播放历史，返回预设视频）
    final videos = await tutorialProvider.getFrequentlyPlayedVideos(limit: 3);
    if (mounted) {
      setState(() {
        _frequentVideos = videos;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final statisticsProvider = context.watch<StatisticsProvider>();
    final exerciseProvider = context.watch<ExerciseProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await statisticsProvider.refresh();
            await exerciseProvider.loadExercises();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题 + 统计入口
                _buildHeader(context, isDark),
                const SizedBox(height: 20),

                // 常练习的运动（推荐教程视频）- 移到今日运动上面
                _buildUsuallyExercised(context, isDark),
                const SizedBox(height: 20),

                // 今日统计（紧凑3列）
                _buildTodayStats(statisticsProvider, isDark),
                const SizedBox(height: 20),

                // 快速开始
                _buildQuickStart(context, isDark),
                const SizedBox(height: 20),

                // 最近记录
                _buildRecentRecords(exerciseProvider, isDark),
                const SizedBox(height: 20),

                // 本周数据mini卡片
                _buildWeekStats(statisticsProvider, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '运动中心',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              app_date_utils.DateUtils.formatDate(DateTime.now()),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => context.push('/statistics'),
          child: NeumorphicContainer(
            isDark: isDark,
            padding: const EdgeInsets.all(12),
            borderRadius: 12,
            child: Icon(
              Icons.bar_chart_rounded,
              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStats(StatisticsProvider provider, bool isDark) {
    final stats = provider.todayStats;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今日运动',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: '时长',
                value: stats.totalDuration.toString(),
                unit: '分钟',
                icon: Icons.timer_outlined,
                iconColor: AppColors.runningColor,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                title: '热量',
                value: stats.totalCalories.toStringAsFixed(0),
                unit: 'kcal',
                icon: Icons.local_fire_department_outlined,
                iconColor: AppColors.cyclingColor,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                title: '次数',
                value: stats.exerciseCount.toString(),
                unit: '次',
                icon: Icons.fitness_center_outlined,
                iconColor: primaryColor,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStart(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快速开始',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.9,
          children: [
            // 室内运动 - 弹出选择跟随视频/自由
            _ExerciseTypeCard(
              icon: '🏠',
              label: '室内运动',
              color: AppColors.gymColor,
              isDark: isDark,
              onTap: () => _showIndoorExercisePicker(context, isDark),
            ),
            // 跑步
            _ExerciseTypeCard(
              icon: ExerciseType.running.icon,
              label: '跑步',
              color: AppColors.runningColor,
              isDark: isDark,
              onTap: () => context.push('/exercise/active', extra: ExerciseType.running),
            ),
            // 骑行
            _ExerciseTypeCard(
              icon: ExerciseType.cycling.icon,
              label: '骑行',
              color: AppColors.cyclingColor,
              isDark: isDark,
              onTap: () => context.push('/exercise/active', extra: ExerciseType.cycling),
            ),
            // 健走
            _ExerciseTypeCard(
              icon: ExerciseType.walking.icon,
              label: '健走',
              color: AppColors.walkingColor,
              isDark: isDark,
              onTap: () => context.push('/exercise/active', extra: ExerciseType.walking),
            ),
          ],
        ),
      ],
    );
  }

  /// 显示室内运动选择器
  void _showIndoorExercisePicker(BuildContext context, bool isDark) {
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '选择室内运动类型',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 20),
            // 跟随视频
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text('🎬', style: const TextStyle(fontSize: 24)),
                ),
              ),
              title: Text(
                '跟随视频',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              subtitle: Text(
                '播放教学视频进行运动',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/exercise/add', extra: {
                  'indoorSubType': IndoorExerciseSubType.followVideo,
                });
              },
            ),
            const SizedBox(height: 8),
            // 自由
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text('💪', style: const TextStyle(fontSize: 24)),
                ),
              ),
              title: Text(
                '自由运动',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              subtitle: Text(
                '手动输入运动数据',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/exercise/add', extra: {
                  'indoorSubType': IndoorExerciseSubType.free,
                });
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 常练习的运动（本地缓存播放最多的视频）
  Widget _buildUsuallyExercised(BuildContext context, bool isDark) {
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    // 使用本地缓存的播放最多视频，而不是请求API
    final videos = _frequentVideos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '常练习的运动',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            GestureDetector(
              onTap: () async {
                // 清空播放历史
                await context.read<TutorialProvider>().clearVideoHistory();
                // 设置为空列表（清空列表后不显示默认视频）
                if (mounted) {
                  setState(() {
                    _frequentVideos = [];
                  });
                }
              },
              child: Text(
                '清空列表',
                style: TextStyle(
                  fontSize: 14,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (videos.isEmpty)
          NeumorphicContainer(
            isDark: isDark,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                '暂无推荐',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ),
          )
        else
          ...videos.map((video) => _buildVideoItem(context, video, isDark)),
      ],
    );
  }

  /// 构建视频推荐项
  Widget _buildVideoItem(BuildContext context, TutorialVideo video, bool isDark) {
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NeumorphicContainer(
        isDark: isDark,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 视频封面缩略图
            GestureDetector(
              onTap: () => context.push('/tutorials/${video.id}'),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      video.thumbnailUrlResolved,
                      width: 80,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 50,
                          color: primaryColor.withOpacity(0.2),
                          child: Icon(
                            Icons.play_circle_outline,
                            color: primaryColor,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                  // 时长标签
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video.durationFormatted,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 视频信息
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/tutorials/${video.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video.difficultyText,
                            style: TextStyle(
                              fontSize: 10,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 播放按钮
            GestureDetector(
              onTap: () => context.push('/tutorials/${video.id}'),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRecords(ExerciseProvider provider, bool isDark) {
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final exercises = provider.exercises.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '最近记录',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            if (exercises.isNotEmpty)
              GestureDetector(
                onTap: () => _showAllRecords(context),
                child: Text(
                  '查看全部',
                  style: TextStyle(
                    fontSize: 14,
                    color: primaryColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (exercises.isEmpty)
          _buildEmptyRecords(isDark)
        else
          ...exercises.map((e) => _buildRecordItem(e, isDark)),
      ],
    );
  }

  Widget _buildEmptyRecords(bool isDark) {
    return NeumorphicContainer(
      isDark: isDark,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.directions_run_outlined,
              size: 40,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              '暂无运动记录',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordItem(ExerciseModel exercise, bool isDark) {
    Color typeColor;
    String typeIcon;
    String typeName;

    // 处理室内运动的子类型
    if (exercise.type == ExerciseType.gym && exercise.indoorSubType != null) {
      typeColor = AppColors.gymColor;
      switch (exercise.indoorSubType!) {
        case IndoorExerciseSubType.followVideo:
          typeIcon = '🎬';
          typeName = '跟随视频';
          break;
        case IndoorExerciseSubType.free:
          typeIcon = '💪';
          typeName = '自由运动';
          break;
      }
    } else {
      // 原有运动类型
      switch (exercise.type) {
        case ExerciseType.running:
          typeColor = AppColors.runningColor;
          typeIcon = exercise.type.icon;
          typeName = exercise.type.displayName;
          break;
        case ExerciseType.cycling:
          typeColor = AppColors.cyclingColor;
          typeIcon = exercise.type.icon;
          typeName = exercise.type.displayName;
          break;
        case ExerciseType.walking:
          typeColor = AppColors.walkingColor;
          typeIcon = exercise.type.icon;
          typeName = exercise.type.displayName;
          break;
        case ExerciseType.gym:
          typeColor = AppColors.gymColor;
          typeIcon = exercise.type.icon;
          typeName = exercise.type.displayName;
          break;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => context.push('/exercise/${exercise.id}'),
        child: NeumorphicContainer(
          isDark: isDark,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    typeIcon,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      _formatRecordDetail(exercise),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRecordDetail(ExerciseModel exercise) {
    final duration = exercise.duration;
    final distance = exercise.distance;
    final calories = exercise.calories;

    final parts = <String>[];

    // 如果是跟随视频类型，显示视频标题
    if (exercise.indoorSubType == IndoorExerciseSubType.followVideo &&
        exercise.videoTitle != null) {
      parts.add(exercise.videoTitle!);
    }

    if (distance > 0) {
      parts.add('${distance.toStringAsFixed(1)}km');
    }
    parts.add('$duration分钟');
    if (calories > 0) {
      parts.add('${calories.toStringAsFixed(0)}kcal');
    }
    return parts.join(' · ');
  }

  Widget _buildWeekStats(StatisticsProvider provider, bool isDark) {
    final weekStats = provider.weekStats;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return GestureDetector(
      onTap: () => context.push('/statistics'),
      child: NeumorphicContainer(
        isDark: isDark,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '本周累计',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${weekStats.totalDuration}分钟 / ${weekStats.totalDistance.toStringAsFixed(1)}km',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(
                    '详情',
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllRecords(BuildContext context) {
    // 跳转到运动记录列表（暂时用add页面作为占位，后续可创建独立页面）
    _showRecordsBottomSheet(context);
  }

  void _showRecordsBottomSheet(BuildContext context) {
    final exerciseProvider = context.read<ExerciseProvider>();
    final themeProvider = context.read<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final exercises = exerciseProvider.exercises;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '运动记录',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: exercises.isEmpty
                    ? Center(
                        child: Text(
                          '暂无记录',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = exercises[index];
                          return _buildRecordItem(exercise, isDark);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseTypeCard extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ExerciseTypeCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NeumorphicContainer(
        isDark: isDark,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
