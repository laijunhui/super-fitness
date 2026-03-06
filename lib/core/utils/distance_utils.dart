import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// GPS距离计算工具
class DistanceUtils {
  DistanceUtils._();

  /// 地球半径（米）
  static const double earthRadius = 6371000;

  /// 使用Haversine公式计算两点间距离
  ///
  /// [lat1] 第一个点纬度
  /// [lon1] 第一个点经度
  /// [lat2] 第二个点纬度
  /// [lon2] 第二个点经度
  ///
  /// 返回距离（米）
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// 使用LatLng计算两点间距离
  ///
  /// [from] 起点
  /// [to] 终点
  ///
  /// 返回距离（米）
  static double calculateDistanceFromLatLng(LatLng from, LatLng to) {
    return calculateDistance(from.latitude, from.longitude, to.latitude, to.longitude);
  }

  /// 计算GPS轨迹总距离
  ///
  /// [points] GPS点列表 [{latitude, longitude}, ...]
  ///
  /// 返回总距离（米）
  static double calculateTotalDistance(List<Map<String, double>> points) {
    if (points.length < 2) return 0;

    double totalDistance = 0;
    for (int i = 0; i < points.length - 1; i++) {
      final from = points[i];
      final to = points[i + 1];

      totalDistance += calculateDistance(
        from['latitude']!,
        from['longitude']!,
        to['latitude']!,
        to['longitude']!,
      );
    }

    return totalDistance;
  }

  /// 计算平均速度
  ///
  /// [distance] 距离（米）
  /// [durationSeconds] 时长（秒）
  ///
  /// 返回速度（米/秒）
  static double calculateAverageSpeed(double distance, int durationSeconds) {
    if (durationSeconds <= 0) return 0;
    return distance / durationSeconds;
  }

  /// 米/秒 转 公里/小时
  static double mpsToKmh(double mps) {
    return mps * 3.6;
  }

  /// 公里/小时 转 米/秒
  static double kmhToMps(double kmh) {
    return kmh / 3.6;
  }

  /// 格式化距离显示
  ///
  /// [meters] 距离（米）
  ///
  /// 返回格式化字符串，如 "5.23 km" 或 "523 m"
  static String formatDistance(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return '${km.toStringAsFixed(2)} km';
    } else {
      return '${meters.toStringAsFixed(0)} m';
    }
  }

  /// 格式化速度显示
  ///
  /// [mps] 速度（米/秒）
  ///
  /// 返回格式化字符串，如 "12.5 km/h"
  static String formatSpeed(double mps) {
    final kmh = mpsToKmh(mps);
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  /// 度转弧度
  static double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}

/// GPS点模型
class GPSPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? altitude;
  final double? speed;

  const GPSPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.altitude,
    this.speed,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'altitude': altitude,
      'speed': speed,
    };
  }

  factory GPSPoint.fromJson(Map<String, dynamic> json) {
    return GPSPoint(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
      altitude: json['altitude'] as double?,
      speed: json['speed'] as double?,
    );
  }
}
