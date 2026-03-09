import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/tutorial_video.dart';
import '../../../data/services/bilibili_api_service.dart';
import '../../providers/tutorial_provider.dart';
import '../../providers/theme_provider.dart';

/// 教程列表页
class TutorialsScreen extends StatefulWidget {
  const TutorialsScreen({super.key});

  @override
  State<TutorialsScreen> createState() => _TutorialsScreenState();
}

class _TutorialsScreenState extends State<TutorialsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TutorialProvider>().loadVideos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final tutorialProvider = context.watch<TutorialProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('健身教程'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
      body: tutorialProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => tutorialProvider.loadVideos(),
              child: Column(
                children: [
                  // 性别筛选
                  _buildGenderFilter(tutorialProvider, isDark),
                  // 分类筛选
                  _buildCategoryFilter(tutorialProvider, isDark),
                  // 视频列表
                  Expanded(
                    child: _buildVideoList(tutorialProvider, isDark),
                  ),
                ],
              ),
            ),
    );
  }

  /// 构建性别筛选栏
  Widget _buildGenderFilter(TutorialProvider provider, bool isDark) {
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '性别:',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(width: 12),
          _buildGenderChip('全部', GenderFilter.all, provider, primaryColor),
          const SizedBox(width: 8),
          _buildGenderChip('男', GenderFilter.male, provider, primaryColor),
          const SizedBox(width: 8),
          _buildGenderChip('女', GenderFilter.female, provider, primaryColor),
        ],
      ),
    );
  }

  Widget _buildGenderChip(String label, GenderFilter gender, TutorialProvider provider, Color primaryColor) {
    final isSelected = provider.genderFilter == gender;

    return GestureDetector(
      onTap: () => provider.setGenderFilter(gender),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 构建分类筛选栏
  Widget _buildCategoryFilter(TutorialProvider provider, bool isDark) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: VideoCategory.categories.length,
        itemBuilder: (context, index) {
          final category = VideoCategory.categories[index];
          final isSelected = provider.selectedCategory == category;
          final primaryColor =
              isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => provider.setCategory(category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  VideoCategory.getDisplayName(category),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建视频列表
  Widget _buildVideoList(TutorialProvider provider, bool isDark) {
    final videos = provider.filteredVideos;

    if (videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无视频',
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return _VideoCard(
          video: video,
          isDark: isDark,
          onTap: () {
            debugPrint('点击视频: ${video.title}, YouTube ID: ${video.videoId}');
            context.push('/tutorials/${video.videoId}');
          },
        );
      },
    );
  }

  /// 显示搜索对话框
  void _showSearchDialog(BuildContext context) {
    final provider = context.read<TutorialProvider>();
    _searchController.text = provider.searchQuery;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索教程'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '输入关键词搜索',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            provider.search(value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.clearSearch();
              Navigator.pop(context);
            },
            child: const Text('清除'),
          ),
          TextButton(
            onPressed: () {
              provider.search(_searchController.text);
              Navigator.pop(context);
            },
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }
}

/// 视频卡片组件
class _VideoCard extends StatelessWidget {
  final TutorialVideo video;
  final bool isDark;
  final VoidCallback onTap;

  const _VideoCard({
    required this.video,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 视频封面
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  Image.network(
                    video.thumbnailUrlResolved,
                    width: 120,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 90,
                        color: primaryColor.withOpacity(0.2),
                        child: Icon(
                          Icons.play_circle_outline,
                          color: primaryColor,
                          size: 40,
                        ),
                      );
                    },
                  ),
                  // 时长标签
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video.durationFormatted,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 视频信息
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // 显示UP主/作者
                    if (video.author.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 12,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              video.author,
                              style: TextStyle(
                                fontSize: 11,
                                color: primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      video.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // 播放量
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 14,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          video.viewCountText,
                          style: TextStyle(
                            fontSize: 11,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 难度
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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
                        const SizedBox(width: 8),
                        // 发布时间
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          video.publishDateText,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
