import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 视频播放历史记录
class VideoPlayRecord {
  final String videoId;
  int playCount;
  DateTime lastPlayedAt;
  String? title;
  String? thumbnailUrl;
  String? source;

  VideoPlayRecord({
    required this.videoId,
    required this.playCount,
    required this.lastPlayedAt,
    this.title,
    this.thumbnailUrl,
    this.source,
  });

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'playCount': playCount,
        'lastPlayedAt': lastPlayedAt.toIso8601String(),
        'title': title,
        'thumbnailUrl': thumbnailUrl,
        'source': source,
      };

  factory VideoPlayRecord.fromJson(Map<String, dynamic> json) => VideoPlayRecord(
        videoId: json['videoId'] as String,
        playCount: json['playCount'] as int,
        lastPlayedAt: DateTime.parse(json['lastPlayedAt'] as String),
        title: json['title'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        source: json['source'] as String?,
      );
}

/// 视频播放历史服务 - 本地存储用户常播放的视频
class VideoHistoryService {
  static const String _storageKey = 'video_play_history';
  final SharedPreferences _prefs;

  VideoHistoryService(this._prefs);

  /// 获取所有播放记录（按播放次数降序）
  List<VideoPlayRecord> getAllRecords() {
    final String? data = _prefs.getString(_storageKey);
    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> jsonList = json.decode(data);
      final records = jsonList
          .map((e) => VideoPlayRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      // 按播放次数降序排序
      records.sort((a, b) => b.playCount.compareTo(a.playCount));
      return records;
    } catch (e) {
      return [];
    }
  }

  /// 记录视频播放 - 每次播放增加计数
  /// 可以传入视频信息用于显示
  Future<void> recordPlay(
    String videoId, {
    String? title,
    String? thumbnailUrl,
    String? source,
  }) async {
    final records = getAllRecords();
    final index = records.indexWhere((r) => r.videoId == videoId);

    if (index >= 0) {
      // 已存在，增加播放次数，更新信息
      records[index].playCount++;
      records[index].lastPlayedAt = DateTime.now();
      // 如果之前没有标题，尝试更新
      if (records[index].title == null && title != null) {
        records[index].title = title;
      }
      if (records[index].thumbnailUrl == null && thumbnailUrl != null) {
        records[index].thumbnailUrl = thumbnailUrl;
      }
      if (records[index].source == null && source != null) {
        records[index].source = source;
      }
    } else {
      // 新记录
      records.add(VideoPlayRecord(
        videoId: videoId,
        playCount: 1,
        lastPlayedAt: DateTime.now(),
        title: title,
        thumbnailUrl: thumbnailUrl,
        source: source,
      ));
    }

    await _saveRecords(records);
  }

  /// 获取所有播放记录（包含视频信息）
  List<VideoPlayRecord> getAllRecordsWithInfo() {
    return getAllRecords();
  }

  /// 获取常播放的视频ID列表（排除指定ID）
  List<String> getFrequentlyPlayedIds({String? excludeId, int limit = 4}) {
    final records = getAllRecords();
    return records
        .where((r) => r.videoId != excludeId)
        .take(limit)
        .map((r) => r.videoId)
        .toList();
  }

  /// 获取播放次数
  int getPlayCount(String videoId) {
    final records = getAllRecords();
    final record = records.where((r) => r.videoId == videoId).firstOrNull;
    return record?.playCount ?? 0;
  }

  Future<void> _saveRecords(List<VideoPlayRecord> records) async {
    final jsonList = records.map((r) => r.toJson()).toList();
    await _prefs.setString(_storageKey, json.encode(jsonList));
  }

  /// 清空历史记录
  Future<void> clearHistory() async {
    await _prefs.remove(_storageKey);
  }
}
