import 'dart:convert';
import '../../core/constants/app_constants.dart';
import '../../core/utils/distance_utils.dart';

/// 室内运动子类型
enum IndoorExerciseSubType {
  followVideo,  // 跟随视频
  free,         // 自由
}

/// 运动记录数据模型
class ExerciseModel {
  final String id;
  final ExerciseType type;
  final double distance;
  final int duration;
  final double calories;
  final List<GPSPoint>? gpsPoints;
  final DateTime createdAt;
  final String? notes;
  // 新增：室内运动子类型
  final IndoorExerciseSubType? indoorSubType;
  // 新增：视频相关信息（跟随视频类型使用）
  final String? videoTitle;
  final String? videoUrl;

  ExerciseModel({
    required this.id,
    required this.type,
    required this.distance,
    required this.duration,
    required this.calories,
    this.gpsPoints,
    required this.createdAt,
    this.notes,
    this.indoorSubType,
    this.videoTitle,
    this.videoUrl,
  });

  /// 从Map创建
  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    List<GPSPoint>? gpsPoints;
    if (map['gps_points'] != null && map['gps_points'].toString().isNotEmpty) {
      final List<dynamic> jsonList = json.decode(map['gps_points']);
      gpsPoints = jsonList.map((e) => GPSPoint.fromJson(e)).toList();
    }

    // 解析室内运动子类型
    IndoorExerciseSubType? indoorSubType;
    if (map['indoor_sub_type'] != null) {
      final subTypeStr = map['indoor_sub_type'].toString();
      if (subTypeStr.isNotEmpty) {
        indoorSubType = IndoorExerciseSubType.values.firstWhere(
          (e) => e.name == subTypeStr,
          orElse: () => IndoorExerciseSubType.free,
        );
      }
    }

    return ExerciseModel(
      id: map['id'],
      type: ExerciseType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ExerciseType.gym,
      ),
      distance: map['distance']?.toDouble() ?? 0,
      duration: map['duration'] ?? 0,
      calories: map['calories']?.toDouble() ?? 0,
      gpsPoints: gpsPoints,
      createdAt: DateTime.parse(map['created_at']),
      notes: map['notes'],
      indoorSubType: indoorSubType,
      videoTitle: map['video_title'],
      videoUrl: map['video_url'],
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'distance': distance,
      'duration': duration,
      'calories': calories,
      'gps_points': gpsPoints != null
          ? json.encode(gpsPoints!.map((e) => e.toJson()).toList())
          : null,
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
      'indoor_sub_type': indoorSubType?.name,
      'video_title': videoTitle,
      'video_url': videoUrl,
    };
  }

  /// 复制
  ExerciseModel copyWith({
    String? id,
    ExerciseType? type,
    double? distance,
    int? duration,
    double? calories,
    List<GPSPoint>? gpsPoints,
    DateTime? createdAt,
    String? notes,
    IndoorExerciseSubType? indoorSubType,
    String? videoTitle,
    String? videoUrl,
  }) {
    return ExerciseModel(
      id: id ?? this.id,
      type: type ?? this.type,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      calories: calories ?? this.calories,
      gpsPoints: gpsPoints ?? this.gpsPoints,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      indoorSubType: indoorSubType ?? this.indoorSubType,
      videoTitle: videoTitle ?? this.videoTitle,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }
}

/// 室内运动子类型扩展方法
extension IndoorExerciseSubTypeExtension on IndoorExerciseSubType {
  String get displayName {
    switch (this) {
      case IndoorExerciseSubType.followVideo:
        return '跟随视频';
      case IndoorExerciseSubType.free:
        return '自由';
    }
  }

  String get icon {
    switch (this) {
      case IndoorExerciseSubType.followVideo:
        return '🎬';
      case IndoorExerciseSubType.free:
        return '💪';
    }
  }
}
