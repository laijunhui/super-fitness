import 'dart:convert';
import '../../core/constants/app_constants.dart';
import '../../core/utils/distance_utils.dart';

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

  ExerciseModel({
    required this.id,
    required this.type,
    required this.distance,
    required this.duration,
    required this.calories,
    this.gpsPoints,
    required this.createdAt,
    this.notes,
  });

  /// 从Map创建
  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    List<GPSPoint>? gpsPoints;
    if (map['gps_points'] != null && map['gps_points'].toString().isNotEmpty) {
      final List<dynamic> jsonList = json.decode(map['gps_points']);
      gpsPoints = jsonList.map((e) => GPSPoint.fromJson(e)).toList();
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
    );
  }
}
