import 'package:flutter/foundation.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';

/// 地图状态管理
class MapProvider extends ChangeNotifier {
  LatLng? _currentLocation;
  final List<LatLng> _trackPoints = [];
  bool _isMapReady = false;
  bool _isTracking = false;
  String? _error;

  // Getters
  LatLng? get currentLocation => _currentLocation;
  List<LatLng> get trackPoints => _trackPoints;
  bool get isMapReady => _isMapReady;
  bool get isTracking => _isTracking;
  String? get error => _error;
  bool get hasTrack => _trackPoints.isNotEmpty;

  /// 设置地图就绪状态
  void setMapReady(bool ready) {
    _isMapReady = ready;
    notifyListeners();
  }

  /// 开始追踪
  void startTracking() {
    _isTracking = true;
    _trackPoints.clear();
    notifyListeners();
  }

  /// 停止追踪
  void stopTracking() {
    _isTracking = false;
    notifyListeners();
  }

  /// 更新当前位置
  void updateCurrentLocation(double lat, double lng) {
    _currentLocation = LatLng(lat, lng);
    if (_isTracking) {
      _trackPoints.add(_currentLocation!);
    }
    notifyListeners();
  }

  /// 添加轨迹点
  void addTrackPoint(LatLng point) {
    if (_isTracking) {
      _trackPoints.add(point);
      notifyListeners();
    }
  }

  /// 清除轨迹
  void clearTrack() {
    _trackPoints.clear();
    _currentLocation = null;
    notifyListeners();
  }

  /// 设置错误信息
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
