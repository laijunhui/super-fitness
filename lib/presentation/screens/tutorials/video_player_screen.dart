import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/exercise_model.dart';
import '../../../data/models/tutorial_video.dart';
import '../../providers/tutorial_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/body_metrics_provider.dart';
import '../../providers/statistics_provider.dart';
import 'bilibili_player.dart';

/// 视频播放页
class VideoPlayerScreen extends StatefulWidget {
  final String videoId;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _controller;
  Timer? _playbackTimer;
  DateTime? _pageStartTime;
  bool _hasAutoRecorded = false;

  @override
  void initState() {
    super.initState();
    _initYoutubeController(widget.videoId);
    _pageStartTime = DateTime.now();
    // 3分钟后检查是否需要自动记录
    _playbackTimer = Timer(const Duration(minutes: 3), _onPlaybackComplete);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TutorialProvider>().loadVideoDetail(widget.videoId);
    });
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _controller?.close();
    super.dispose();
  }

  /// 3分钟播放完成后的回调
  void _onPlaybackComplete() {
    if (mounted && !_hasAutoRecorded) {
      // 检查用户是否还在当前页面（通过检查页面开始时间）
      if (_pageStartTime != null) {
        final elapsed = DateTime.now().difference(_pageStartTime!).inMinutes;
        if (elapsed >= 3) {
          _autoSaveExerciseRecord();
        }
      }
    }
  }

  /// 自动保存运动记录
  Future<void> _autoSaveExerciseRecord() async {
    if (_hasAutoRecorded) return;
    _hasAutoRecorded = true;

    final tutorialProvider = context.read<TutorialProvider>();
    final video = tutorialProvider.currentVideo;
    if (video == null) return;

    // 计算卡路里估算
    final durationMinutes = video.duration ~/ 60;
    final bodyMetrics = context.read<BodyMetricsProvider>().latestBodyMetrics;
    final weight = bodyMetrics?.weight ?? 70;

    // 使用中等强度 MET 值（约5.5）估算
    final calories = _estimateCalories(durationMinutes, weight);

    // 添加运动记录
    await context.read<ExerciseProvider>().addIndoorExercise(
      subType: IndoorExerciseSubType.followVideo,
      duration: durationMinutes,
      calories: calories,
      videoTitle: video.title,
      videoUrl: video.videoId,
    );

    // 刷新统计
    if (mounted) {
      context.read<StatisticsProvider>().loadStatistics();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已自动记录运动：${video.title}（$durationMinutes 分钟）'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 估算卡路里（使用健身 MET 值约5.5）
  double _estimateCalories(int durationMinutes, double weight) {
    const met = 5.5; // 中等强度健身
    final durationHours = durationMinutes / 60;
    return met * weight * durationHours;
  }

  void _initYoutubeController(String videoId) {
    // 使用已知有效的视频ID进行测试（Rick Astley - Never Gonna Give You Up）
    const testVideoId = 'dQw4w9WgXcQ';
    final actualVideoId = videoId.isNotEmpty ? videoId : testVideoId;

    _controller = YoutubePlayerController.fromVideoId(
      videoId: actualVideoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        enableJavaScript: true,
      ),
    );
  }

  /// 根据视频来源构建对应的播放器
  Widget _buildPlayer(TutorialVideo video) {
    switch (video.source) {
      case VideoSource.bilibili:
        // B站视频
        return BilibiliPlayer(
          bvid: video.videoId,
          title: video.title,
        );
      case VideoSource.youtube:
      case VideoSource.local:
      default:
        // YouTube 或本地视频
        if (_controller != null) {
          return YoutubePlayer(
            controller: _controller!,
            aspectRatio: 16 / 9,
          );
        } else {
          return Container(
            height: 220,
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
    }
  }

  Future<void> _openInBrowser() async {
    final url = Uri.parse('https://www.youtube.com/watch?v=${widget.videoId}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final tutorialProvider = context.watch<TutorialProvider>();
    final isDark = themeProvider.isDarkMode;
    final video = tutorialProvider.currentVideo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('视频播放'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 在离开前检查是否满足自动记录条件
            if (!_hasAutoRecorded && _pageStartTime != null) {
              final elapsed = DateTime.now().difference(_pageStartTime!).inMinutes;
              if (elapsed >= 3) {
                _autoSaveExerciseRecord();
              }
            }
            tutorialProvider.clearCurrentVideo();
            context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: _openInBrowser,
            tooltip: '在浏览器中打开',
          ),
        ],
      ),
      body: tutorialProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : video == null
              ? _buildNotFound(isDark)
              : _buildContent(video, tutorialProvider, isDark),
    );
  }

  Widget _buildNotFound(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            '视频不存在',
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

  Widget _buildContent(
    TutorialVideo video,
    TutorialProvider provider,
    bool isDark,
  ) {
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 视频播放器
          _buildPlayer(video),

          // 视频信息
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  video.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // 统计信息
                Row(
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 18,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${video.viewCountText} 播放',
                      style: TextStyle(
                        fontSize: 13,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video.difficultyText,
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      video.durationFormatted,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 分割线
                Container(
                  height: 1,
                  color: isDark
                      ? AppColors.darkTextSecondary.withOpacity(0.2)
                      : AppColors.lightTextSecondary.withOpacity(0.2),
                ),
                const SizedBox(height: 16),

                // 简介
                Text(
                  '课程简介',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  video.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),

                // 相关推荐
                if (provider.relatedVideos.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    height: 1,
                    color: isDark
                        ? AppColors.darkTextSecondary.withOpacity(0.2)
                        : AppColors.lightTextSecondary.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '相关推荐',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRelatedVideos(provider, isDark),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建相关推荐视频
  Widget _buildRelatedVideos(TutorialProvider provider, bool isDark) {
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: provider.relatedVideos.length,
        itemBuilder: (context, index) {
          final video = provider.relatedVideos[index];
          return GestureDetector(
            onTap: () {
              // 重新加载新视频 - 使用 YouTube ID
              provider.loadVideoDetail(video.videoId);
              // 重置YouTube控制器
              _controller?.loadVideo(video.videoId);
              // 重置计时器
              _pageStartTime = DateTime.now();
              _hasAutoRecorded = false;
              _playbackTimer?.cancel();
              _playbackTimer = Timer(const Duration(minutes: 3), _onPlaybackComplete);
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 缩略图
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          video.thumbnailUrlResolved,
                          width: 140,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 140,
                              height: 60,
                              color: primaryColor.withOpacity(0.2),
                              child: Icon(
                                Icons.play_circle_outline,
                                color: primaryColor,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
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
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    video.title,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
