import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/theme_provider.dart';

/// 成就页面
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AchievementProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final achievementProvider = context.watch<AchievementProvider>();
    final isDark = themeProvider.isDarkMode;

    // 显示新成就解锁弹窗
    if (achievementProvider.newlyUnlocked != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUnlockDialog(context, achievementProvider.newlyUnlocked!);
        achievementProvider.clearNewlyUnlocked();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('成就'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: achievementProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 成就统计
                  _buildStatsCard(achievementProvider, isDark),
                  const SizedBox(height: 24),

                  // 成就列表
                  Text(
                    '成就列表',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAchievementsGrid(achievementProvider, isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard(AchievementProvider provider, bool isDark) {
    return NeumorphicContainer(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.emoji_events,
              value: '${provider.unlockedCount}',
              label: '已解锁',
              isDark: isDark,
            ),
            Container(
              width: 1,
              height: 40,
              color: isDark ? AppColors.darkShadowDark : AppColors.lightShadowDark,
            ),
            _buildStatItem(
              icon: Icons.star,
              value: '${provider.achievements.length}',
              label: '总成就',
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsGrid(AchievementProvider provider, bool isDark) {
    final achievements = provider.achievements;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _buildAchievementCard(achievement, isDark);
      },
    );
  }

  Widget _buildAchievementCard(achievement, bool isDark) {
    final isUnlocked = achievement.isUnlocked;

    return Container(
      decoration: BoxDecoration(
        color: isUnlocked
            ? (isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground)
            : (isDark ? AppColors.darkShadowDark : AppColors.lightShadowDark).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: isUnlocked
            ? Border.all(
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                width: 2,
              )
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            achievement.icon,
            style: TextStyle(
              fontSize: 32,
              color: isUnlocked ? null : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isUnlocked
                  ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                  : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            style: TextStyle(
              fontSize: 10,
              color: isUnlocked
                  ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                  : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          if (isUnlocked) ...[
            const SizedBox(height: 4),
            Icon(
              Icons.check_circle,
              size: 16,
              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            ),
          ],
        ],
      ),
    );
  }

  void _showUnlockDialog(BuildContext context, achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(achievement.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 8),
            const Text('成就解锁!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              achievement.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(achievement.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('太棒了!'),
          ),
        ],
      ),
    );
  }
}
