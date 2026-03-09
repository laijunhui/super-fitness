/// 视频来源枚举
enum VideoSource {
  youtube,
  bilibili,
  local,
}

/// 视频难度枚举
enum VideoDifficulty {
  beginner,
  intermediate,
  advanced,
}

/// 教程视频数据模型
class TutorialVideo {
  final String id;
  final String title;
  final String description;
  final String category; // 分类：yoga, hiit, strength, stretching, fatLoss
  final String thumbnailUrl;
  final String videoId; // YouTube视频ID或普通视频URL
  final int duration; // 秒
  final VideoDifficulty difficulty;
  final VideoSource source;
  final int viewCount; // 播放量
  final DateTime publishDate; // 发布时间
  final String author; // UP主/作者

  TutorialVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.thumbnailUrl,
    required this.videoId,
    required this.duration,
    required this.difficulty,
    required this.source,
    this.viewCount = 0,
    required this.publishDate,
    this.author = '',
  });

  /// 获取发布时间格式化文本（yyyy-MM-dd格式）
  String get publishDateText {
    return '${publishDate.year}-${publishDate.month.toString().padLeft(2, '0')}-${publishDate.day.toString().padLeft(2, '0')}';
  }

  /// 获取时长格式化字符串
  String get durationFormatted {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    if (minutes > 0) {
      return seconds > 0 ? '$minutes 分钟$seconds 秒' : '$minutes 分钟';
    }
    return '$seconds 秒';
  }

  /// 获取难度显示文本
  String get difficultyText {
    switch (difficulty) {
      case VideoDifficulty.beginner:
        return '初级';
      case VideoDifficulty.intermediate:
        return '中级';
      case VideoDifficulty.advanced:
        return '高级';
    }
  }

  /// 获取播放量格式化文本
  String get viewCountText {
    if (viewCount >= 10000) {
      return '${(viewCount / 10000).toStringAsFixed(1)}万';
    }
    return viewCount.toString();
  }

  /// 获取YouTube缩略图URL
  String get youtubeThumbnailUrl {
    return 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
  }

  /// 获取封面图URL（根据视频来源返回正确的缩略图）
  String get thumbnailUrlResolved {
    // 如果有自定义缩略图（来自B站等），优先使用
    if (thumbnailUrl.isNotEmpty) {
      return thumbnailUrl;
    }
    // 否则如果是YouTube视频，使用YouTube缩略图
    if (source == VideoSource.youtube) {
      return youtubeThumbnailUrl;
    }
    // B站视频没有缩略图时返回空字符串（显示占位图）
    if (source == VideoSource.bilibili) {
      return '';
    }
    // 默认返回YouTube格式
    return youtubeThumbnailUrl;
  }
}

/// 视频分类
class VideoCategory {
  static const String all = 'all';
  static const String yoga = 'yoga';
  static const String strength = 'strength';
  static const String stretching = 'stretching';
  static const String fatLoss = 'fatLoss';

  static const List<String> categories = [
    all,
    yoga,
    strength,
    stretching,
    fatLoss,
  ];

  static String getDisplayName(String category) {
    switch (category) {
      case all:
        return '全部';
      case yoga:
        return '瑜伽';
      case strength:
        return '力量';
      case stretching:
        return '拉伸';
      case fatLoss:
        return '减脂';
      default:
        return category;
    }
  }
}
