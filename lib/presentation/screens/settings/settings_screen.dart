import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/theme_provider.dart';

/// 设置页
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final isGreen = themeProvider.isGreenMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 外观设置
            Text(
              '外观',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            NeumorphicContainer(
              isDark: isDark,
              child: Column(
                children: [
                  _buildThemeSelector(context, themeProvider, isDark, isGreen),
                  const Divider(),
                  _buildSettingRow(
                    icon: Icons.dark_mode,
                    title: '深色模式',
                    trailing: Switch(
                      value: isDark,
                      onChanged: (_) => themeProvider.toggleTheme(),
                      activeColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    ),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 运动功能
            Text(
              '运动',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            NeumorphicContainer(
              isDark: isDark,
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: Icons.flag_outlined,
                    title: '运动目标与提醒',
                    trailing: const Icon(Icons.chevron_right),
                    isDark: isDark,
                    onTap: () => context.push('/goals'),
                  ),
                  const Divider(),
                  _buildSettingRow(
                    icon: Icons.emoji_events_outlined,
                    title: '成就',
                    trailing: const Icon(Icons.chevron_right),
                    isDark: isDark,
                    onTap: () => context.push('/achievements'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 关于
            Text(
              '关于',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            NeumorphicContainer(
              isDark: isDark,
              child: Column(
                children: [
                  _buildAboutRow('应用版本', '2.0.0', isDark),
                  const Divider(),
                  _buildAboutRow('开发者', 'Super Fitness Team', isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, ThemeProvider provider, bool isDark, bool isGreen) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '主题模式',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildThemeButton(
                context: context,
                mode: AppThemeMode.light,
                label: '浅色',
                icon: Icons.light_mode,
                isSelected: !isDark && !isGreen,
                provider: provider,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildThemeButton(
                context: context,
                mode: AppThemeMode.dark,
                label: '深色',
                icon: Icons.dark_mode,
                isSelected: isDark,
                provider: provider,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildThemeButton(
                context: context,
                mode: AppThemeMode.green,
                label: '绿植',
                icon: Icons.eco,
                isSelected: isGreen,
                provider: provider,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeButton({
    required BuildContext context,
    required AppThemeMode mode,
    required String label,
    required IconData icon,
    required bool isSelected,
    required ThemeProvider provider,
    required bool isDark,
  }) {
    Color primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    if (mode == AppThemeMode.green) {
      primaryColor = AppColors.greenThemePrimary;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setThemeMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? primaryColor : (isDark ? AppColors.darkShadowDark : AppColors.lightShadowDark),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required Widget trailing,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildAboutRow(String label, String value, bool isDark) {
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
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
