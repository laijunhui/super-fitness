import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/tutorial_video.dart';

/// B站视频数据模型（API返回）
class BilibiliVideoItem {
  final String bvid;
  final String title;
  final String description;
  final String author;
  final int duration; // 秒
  final int viewCount;
  final int publishDate; // 时间戳
  final String coverUrl; // 封面图URL

  BilibiliVideoItem({
    required this.bvid,
    required this.title,
    required this.description,
    required this.author,
    required this.duration,
    required this.viewCount,
    required this.publishDate,
    this.coverUrl = '',
  });

  /// 从API响应转换
  factory BilibiliVideoItem.fromApiJson(Map<String, dynamic> json) {
    final title = json['title'] ?? '';
    final author = json['author'] ?? '';
    final bvid = json['bvid'] ?? '';

    // 解析时长 (格式: 12:34 -> 秒数)
    int durationSec = 0;
    final durationStr = json['duration']?.toString() ?? '';
    if (durationStr.contains(':')) {
      final parts = durationStr.split(':');
      if (parts.length == 2) {
        durationSec = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      } else if (parts.length == 3) {
        durationSec = int.parse(parts[0]) * 3600 + int.parse(parts[1]) * 60 + int.parse(parts[2]);
      }
    }

    // 解析封面图URL - 搜索API返回的是 pic 字段
    String coverUrl = json['pic']?.toString() ?? '';
    // 确保封面URL是完整的
    if (coverUrl.isNotEmpty && !coverUrl.startsWith('http')) {
      coverUrl = 'https:$coverUrl';
    }

    return BilibiliVideoItem(
      bvid: bvid,
      title: title,
      description: json['description'] ?? '',
      author: author,
      duration: durationSec,
      viewCount: int.tryParse(json['play']?.toString() ?? '0') ?? 0,
      publishDate: json['pubdate'] ?? 0,
      coverUrl: coverUrl,
    );
  }

  /// 转换为 TutorialVideo 模型
  TutorialVideo toTutorialVideo(String category) {
    // 根据标题自动判断难度
    VideoDifficulty difficulty = _estimateDifficulty(title);

    // B站视频使用封面图，如果没有封面则使用占位图
    final thumbnail = coverUrl.isNotEmpty ? coverUrl : '';

    return TutorialVideo(
      id: bvid,
      title: _cleanTitle(title),
      description: description.isNotEmpty ? description : '暂无简介',
      category: category,
      thumbnailUrl: thumbnail,
      videoId: bvid,
      duration: duration,
      difficulty: difficulty,
      source: VideoSource.bilibili,
      viewCount: viewCount,
      publishDate: DateTime.fromMillisecondsSinceEpoch(publishDate * 1000),
      author: author,
    );
  }

  /// 清理标题中的html标签
  String _cleanTitle(String rawTitle) {
    return rawTitle
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  /// 根据标题估算难度
  VideoDifficulty _estimateDifficulty(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('初级') || lowerTitle.contains('入门') ||
        lowerTitle.contains('零基础') || lowerTitle.contains('新手')) {
      return VideoDifficulty.beginner;
    } else if (lowerTitle.contains('高级') || lowerTitle.contains('高强度') ||
        lowerTitle.contains('HIIT') || lowerTitle.contains('暴汗')) {
      return VideoDifficulty.advanced;
    }
    return VideoDifficulty.intermediate;
  }
}

/// 搜索排序方式
enum SearchOrder {
  click,    // 热度
  pubdate,  // 发布时间
  mix,      // 综合
}

/// 性别筛选
enum GenderFilter {
  all,    // 全部
  male,   // 男性
  female, // 女性
}

/// B站 API 服务
class BilibiliApiService {
  static const String _searchApi = 'https://api.bilibili.com/x/web-interface/search/type';
  static const String _rankApi = 'https://api.bilibili.com/x/web-interface/ranking/v2';

  final http.Client _client;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 800);

  // 模拟真实浏览器的请求头
  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
    'Accept': '*/*',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
    'Accept-Encoding': 'gzip, deflate, br',
  };

  BilibiliApiService({http.Client? client}) : _client = client ?? http.Client();

  /// 带重试的 HTTP GET 请求
  Future<http.Response?> _getWithRetry(Uri uri, {int retries = _maxRetries}) async {
    for (int i = 0; i < retries; i++) {
      try {
        final response = await _client.get(uri, headers: _headers);
        if (response.statusCode == 200) {
          return response;
        }
        // 412 表示被限流，增加延迟后重试
        if (response.statusCode == 412) {
          debugPrint('请求被限流(412)，等待后重试...');
          await Future.delayed(Duration(milliseconds: 1500 * (i + 1)));
        } else {
          debugPrint('请求失败，状态码: ${response.statusCode}，重试 ${i + 1}/$retries');
        }
      } catch (e) {
        debugPrint('请求异常: $e，重试 ${i + 1}/$retries');
      }
      if (i < retries - 1) {
        await Future.delayed(_retryDelay * (i + 1)); // 递增延迟
      }
    }
    return null;
  }

  /// 搜索视频
  /// [keyword] 搜索关键词
  /// [page] 页码
  /// [pageSize] 每页数量
  /// [order] 排序方式
  /// [gender] 性别筛选
  Future<List<BilibiliVideoItem>> searchVideos({
    required String keyword,
    int page = 1,
    int pageSize = 20,
    SearchOrder order = SearchOrder.click,
    GenderFilter gender = GenderFilter.all,
  }) async {
    debugPrint('=== B站搜索API调用 ===');
    debugPrint('关键词: $keyword, 页码: $page, 每页数量: $pageSize, 排序: $order, 性别: $gender');

    try {
      // 构建搜索参数
      final queryParams = <String, String>{
        'search_type': 'video',
        'keyword': keyword,
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'order': order.name,
      };

      // 添加性别筛选（0: 全部, 1: 男, 2: 女）
      if (gender != GenderFilter.all) {
        queryParams['sex'] = gender == GenderFilter.male ? '1' : '2';
      }

      final uri = Uri.parse(_searchApi).replace(queryParameters: queryParams);

      debugPrint('请求URL: $uri');

      final response = await _getWithRetry(uri);

      if (response == null) {
        debugPrint('请求失败，已达到最大重试次数');
        return [];
      }

      debugPrint('响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('API返回code: ${data['code']}, message: ${data['message']}');

        if (data['code'] == 0 && data['data'] != null) {
          final result = data['data']['result'] as List<dynamic>?;
          if (result != null) {
            // 过滤最近3年的视频
            final threeYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 3));
            final threeYearsAgoTimestamp = threeYearsAgo.millisecondsSinceEpoch ~/ 1000;
            final videos = result
                .map((item) => BilibiliVideoItem.fromApiJson(item as Map<String, dynamic>))
                .where((item) =>
                    item.bvid.isNotEmpty &&
                    item.title.isNotEmpty &&
                    item.publishDate > threeYearsAgoTimestamp)
                .toList();
            debugPrint('解析到视频数量（近3年）: ${videos.length}');
            if (videos.isNotEmpty) {
              debugPrint('第一条视频: ${videos.first.title}');
              debugPrint('发布时间: ${videos.first.publishDate}');
            }
            return videos;
          } else {
            debugPrint('result 为空');
          }
        } else {
          debugPrint('API返回错误: ${data['message']}');
        }
      }
    } catch (e) {
      debugPrint('B站搜索API错误: $e');
    }
    return [];
  }

  /// 获取分区热门视频
  /// [rid] 分区ID (17:生活分区, 28:原创, 31:打扮, 138:运动, 250:动物圈, 234:汽车)
  /// 健身相关分区: 运动(138)
  Future<List<BilibiliVideoItem>> getRankVideos({
    int rid = 138, // 运动分区
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse(_rankApi).replace(queryParameters: {
        'rid': rid.toString(),
        'type': 'all',
        'pn': '1',
        'ps': pageSize.toString(),
      });

      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 0 && data['data'] != null) {
          final list = data['data']['list'] as List<dynamic>?;
          if (list != null) {
            return list
                .map((item) => _parseRankVideo(item as Map<String, dynamic>))
                .where((item) => item.bvid.isNotEmpty && item.title.isNotEmpty)
                .toList();
          }
        }
      }
    } catch (e) {
      debugPrint('B站排行榜API错误: $e');
    }
    return [];
  }

  /// 根据关键词获取健身相关视频（并发查询）
  Future<List<BilibiliVideoItem>> getFitnessVideos({
    int page = 1,
    int pageSize = 20,
    GenderFilter gender = GenderFilter.all,
  }) async {
    // 搜索健身相关关键词
    final keywords = ['健身', '减脂', 'HIIT', '瑜伽', '帕梅拉', '周六野', '燃脂', '拉伸'];

    debugPrint('=== 并发查询健身视频 ===');
    debugPrint('关键词数量: ${keywords.length}');

    // 并发执行所有搜索请求
    final futures = keywords.map((keyword) => searchVideos(
      keyword: keyword,
      page: page,
      pageSize: pageSize,
      gender: gender,
    ));

    // 等待所有请求完成
    final results = await Future.wait(futures, eagerError: false);

    // 合并所有结果
    final allVideos = <BilibiliVideoItem>{};
    for (final videos in results) {
      allVideos.addAll(videos);
    }

    debugPrint('并发查询完成，总视频数: ${allVideos.length}');

    // 按播放量排序
    final videoList = allVideos.toList();
    videoList.sort((a, b) => b.viewCount.compareTo(a.viewCount));

    return videoList.take(pageSize).toList();
  }

  /// 根据分类获取视频
  Future<List<BilibiliVideoItem>> getVideosByCategory({
    required String category,
    int page = 1,
    int pageSize = 20,
    GenderFilter gender = GenderFilter.all,
  }) async {
    debugPrint('=== 获取分类视频 ===');
    debugPrint('分类: $category, 页码: $page, 性别: $gender');

    String keyword;
    switch (category) {
      case 'fatLoss':
        keyword = '减脂 燃脂 有氧';
        break;
      case 'strength':
        keyword = '力量 腹肌 核心';
        break;
      case 'yoga':
        keyword = '瑜伽课程 瑜伽跟练 瑜伽教学';
        break;
      case 'stretching':
        keyword = '拉伸 放松 肩颈';
        break;
      default:
        keyword = '健身 运动';
    }

    debugPrint('搜索关键词: $keyword');

    return searchVideos(
      keyword: keyword,
      page: page,
      pageSize: pageSize,
      gender: gender,
    );
  }

  void dispose() {
    _client.close();
  }

  /// 解析排行榜视频数据
  BilibiliVideoItem _parseRankVideo(Map<String, dynamic> json) {
    final bvid = json['bvid'] ?? '';
    final title = json['title'] ?? '';
    final description = json['desc'] ?? '';
    final author = json['author'] ?? '';
    final durationStr = json['duration']?.toString() ?? '';

    // 解析时长
    int durationSec = 0;
    if (durationStr.contains(':')) {
      final parts = durationStr.split(':');
      if (parts.length == 2) {
        durationSec = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      } else if (parts.length == 3) {
        durationSec = int.parse(parts[0]) * 3600 + int.parse(parts[1]) * 60 + int.parse(parts[2]);
      }
    }

    // 解析封面图URL - 排行榜API返回的是 pic 字段
    String coverUrl = json['pic']?.toString() ?? '';
    if (coverUrl.isNotEmpty && !coverUrl.startsWith('http')) {
      coverUrl = 'https:$coverUrl';
    }

    return BilibiliVideoItem(
      bvid: bvid,
      title: title,
      description: description,
      author: author,
      duration: durationSec,
      viewCount: json['play'] ?? 0,
      publishDate: json['pubdate'] ?? 0,
      coverUrl: coverUrl,
    );
  }
}
