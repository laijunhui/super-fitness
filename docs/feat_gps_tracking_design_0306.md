# GPS轨迹追踪功能技术实现方案

**版本**: 1.0
**日期**: 2026-03-06
**状态**: 技术设计

---

## 1. 技术选型

### 1.1 地图SDK

| 方案 | 库名 | 版本 | 说明 |
|------|------|------|------|
| 主选 | `amap_flutter_map` | ^3.0.0 | 高德地图Flutter插件（包含定位功能） |
| 主选 | `amap_flutter_base` | ^3.0.0 | 高德地图基础库 |

**定位实现方式**：使用 `amap_flutter_map` 的 `AMapWidget.onLocationChanged` 回调获取高德定位，无需额外依赖独立的定位插件。

**备选**（如高德SDK不可用）：
- `flutter_map` + OpenStreetMap（无需API Key）
- `tencentmap_flutter`（腾讯地图）

### 1.2 依赖配置

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter

  # 现有依赖保留
  provider: ^6.1.1
  sqflite: ^2.3.2
  go_router: ^13.2.0

  # 新增：高德地图
  amap_flutter_map: ^3.0.0
  amap_flutter_base: ^3.0.0

  # 工具库
  latlong2: ^0.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

---

## 2. 项目结构设计

### 2.1 新增文件清单

```
lib/
├── core/
│   ├── constants/
│   │   └── map_constants.dart          # 地图常量（API Key占位）
│   ├── utils/
│   │   ├── map_utils.dart              # 地图工具函数
│   │   └── track_utils.dart            # 轨迹处理工具
│   └── widgets/
│       ├── exercise_map_view.dart       # 运动地图组件
│       ├── map_marker.dart              # 地图标记组件
│       └── track_painter.dart           # 轨迹绘制组件
│
├── presentation/
│   ├── providers/
│   │   └── map_provider.dart           # 地图状态管理
│   ├── screens/
│   │   └── exercise/
│   │       ├── active_workout_screen.dart   # 重构：实时运动页
│   │       └── exercise_detail_screen.dart  # 重构：添加地图展示
│   └── widgets/
│       ├── exercise_map_card.dart       # 列表页地图缩略图卡片
│       └── exercise_map_detail.dart     # 详情页地图组件
│
└── router/
    └── app_router.dart                  # 更新路由配置
```

---

## 3. 核心模块设计

### 3.1 地图常量配置

```dart
// lib/core/constants/map_constants.dart

class MapConstants {
  // 高德地图API Key（用户需自行申请）
  // 建议：在应用内提供配置界面或使用环境变量
  static const String androidKey = 'YOUR_ANDROID_API_KEY';
  static const String iosKey = 'YOUR_IOS_API_KEY';

  // 地图默认配置
  static const double defaultZoom = 16.0;        // 默认缩放级别
  static const double minZoom = 3.0;             // 最小缩放
  static const double maxZoom = 18.0;            // 最大缩放

  // 轨迹配置
  static const int locationInterval = 3000;      // GPS采样间隔（毫秒）
  static const double distanceFilter = 10.0;     // 距离过滤（米），新坐标移动超过10米才记录

  // 轨迹线样式
  static const int trackColor = 0xFF6C5CE7;      // 轨迹颜色（紫色）
  static const double trackWidth = 8.0;          // 轨迹宽度

  // 标记点图标
  static const String startMarkerIcon = 'start';
  static const String endMarkerIcon = 'end';
  static const String currentMarkerIcon = 'current';
}
```

### 3.2 地图状态管理

```dart
// lib/presentation/providers/map_provider.dart

import 'package:flutter/foundation.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/map_constants.dart';
import '../../core/utils/distance_utils.dart';

class MapProvider extends ChangeNotifier {
  AMapController? _mapController;
  LatLng? _currentLocation;
  List<LatLng> _trackPoints = [];
  bool _isMapReady = false;
  String? _error;

  // Getters
  LatLng? get currentLocation => _currentLocation;
  List<LatLng> get trackPoints => _trackPoints;
  bool get isMapReady => _isMapReady;
  String? get error => _error;
  AMapController? get mapController => _mapController;

  /// 初始化地图控制器
  void initMapController(AMapController controller) {
    _mapController = controller;
    _isMapReady = true;
    notifyListeners();
  }

  /// 更新当前位置
  void updateCurrentLocation(double lat, double lng) {
    _currentLocation = LatLng(lat, lng);
    _trackPoints.add(_currentLocation!);
    notifyListeners();
  }

  /// 添加轨迹点
  void addTrackPoint(LatLng point) {
    _trackPoints.add(point);
    notifyListeners();
  }

  /// 清除轨迹
  void clearTrack() {
    _trackPoints.clear();
    notifyListeners();
  }

  /// 移动地图到当前位置
  void moveToCurrentLocation() {
    if (_mapController != null && _currentLocation != null) {
      _mapController?.moveCamera(
        CameraUpdate.newLatLng(_currentLocation!),
      );
    }
  }

  /// 调整地图视野以显示所有轨迹点
  void fitTrackBounds() {
    if (_mapController != null && _trackPoints.length >= 2) {
      final bounds = LatLngBounds.fromPoints(_trackPoints);
      _mapController?.moveCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
```

### 3.3 轨迹处理工具

```dart
// lib/core/utils/track_utils.dart

import 'package:latlong2/latlong.dart';
import '../utils/distance_utils.dart';

class TrackUtils {
  /// 平滑轨迹（移除漂移点）
  static List<LatLng> smoothTrack(List<LatLng> points, {double threshold = 10}) {
    if (points.length < 3) return points;

    final smoothed = <LatLng>[points.first];

    for (int i = 1; i < points.length - 1; i++) {
      final prev = smoothed.last;
      final curr = points[i];
      final next = points[i + 1];

      // 计算与前一点的距离
      final distance = const Distance().as(
        LengthUnit.Meter,
        prev,
        curr,
      );

      // 如果距离超过阈值，保留该点
      if (distance > threshold) {
        smoothed.add(curr);
      }
    }

    // 保留最后一个点
    smoothed.add(points.last);

    return smoothed;
  }

  /// 计算轨迹边界
  static LatLngBounds calculateBounds(List<LatLng> points) {
    if (points.isEmpty) return LatLngBounds();

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  /// 计算轨迹总距离（公里）
  static double calculateTotalDistance(List<LatLng> points) {
    if (points.length < 2) return 0;

    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      total += const Distance().as(
        LengthUnit.Meter,
        points[i],
        points[i + 1],
      );
    }

    return total / 1000;
  }

  /// 生成轨迹分段（按时间或距离）
  static List<TrackSegment> splitIntoSegments(
    List<LatLng> points,
    List<DateTime> timestamps, {
    int maxPointsPerSegment = 100,
  }) {
    final segments = <TrackSegment>[];

    for (int i = 0; i < points.length; i += maxPointsPerSegment) {
      final end = (i + maxPointsPerSegment > points.length)
          ? points.length
          : i + maxPointsPerSegment;

      final segmentPoints = points.sublist(i, end);
      final segmentTimes = timestamps.length >= end
          ? timestamps.sublist(i, end)
          : timestamps;

      segments.add(TrackSegment(
        points: segmentPoints,
        timestamps: segmentTimes,
      ));
    }

    return segments;
  }
}

/// 轨迹段
class TrackSegment {
  final List<LatLng> points;
  final List<DateTime> timestamps;

  TrackSegment({required this.points, required this.timestamps});

  double get distance => TrackUtils.calculateTotalDistance(points);

  Duration get duration {
    if (timestamps.isEmpty) return Duration.zero;
    return timestamps.last.difference(timestamps.first);
  }
}
```

---

## 4. 页面实现

### 4.1 核心设计要点

**起点、轨迹点、终点的定位逻辑：**

| 元素 | 定位逻辑 |
|------|----------|
| **起点** | 等待高德地图首次定位回调 (`onLocationChanged`) 完成并获取到坐标后，才显示绿色起点标记，同时作为轨迹第一个点 |
| **轨迹点** | 使用高德地图定位回调获取坐标，距离过滤设置为 **5米**，即新坐标与上一个坐标距离超过5米才记录到轨迹中 |
| **终点** | 运动结束后，**强制**将当前位置作为结束点添加（无论距离上一个点是否超过5米），确保轨迹完整闭合 |
| **异常点过滤** | 当新坐标点与上一个点的距离是上两个点距离的10倍以上时，认为是异常点（GPS漂移或网络抖动），自动跳过不保存 |

### 4.2 实时运动页面核心逻辑

#### 4.2.1 距离过滤与异常点检测

```dart
// 高德定位回调 - 使用高德定位获取轨迹点
onLocationChanged: (location) {
  if (!mounted) return;

  final point = location.latLng;
  final provider = context.read<ExerciseProvider>();
  final trackingPoints = provider.trackingPoints;

  // 首次定位设置起点
  if (!_isFirstAMapLocationReceived) {
    setState(() {
      _startPoint = point;
      _isFirstAMapLocationReceived = true;
    });

    // 首次定位也添加到轨迹
    if (provider.isTracking) {
      final gpsPoint = GPSPoint(
        latitude: point.latitude,
        longitude: point.longitude,
        timestamp: DateTime.now(),
      );
      provider.addTrackingPoint(gpsPoint);
    }
    return;
  }

  // 距离过滤：只有距离超过5米才保存新坐标点
  if (provider.isTracking && trackingPoints.isNotEmpty) {
    final lastPoint = trackingPoints.last;
    final distance = _calculateDistance(
      lastPoint.latitude,
      lastPoint.longitude,
      point.latitude,
      point.longitude,
    );

    // 异常点检测：只有超过5米才检查异常
    if (distance >= 5.0) {
      // 如果有至少3个点，检查距离异常（当前距离相对上次距离超过10倍）
      if (trackingPoints.length >= 3) {
        final secondLastPoint = trackingPoints[trackingPoints.length - 2];
        final prevDistance = _calculateDistance(
          secondLastPoint.latitude,
          secondLastPoint.longitude,
          lastPoint.latitude,
          lastPoint.longitude,
        );

        // 如果当前距离是上次距离的10倍以上，认为是异常点（GPS漂移或网络抖动）
        if (prevDistance > 0 && distance / prevDistance > 10) {
          debugPrint('DEBUG: Abnormal point detected and removed!');
          return; // 跳过这个异常点
        }
      }

      // 正常点，添加到轨迹
      final gpsPoint = GPSPoint(
        latitude: point.latitude,
        longitude: point.longitude,
        timestamp: DateTime.now(),
      );
      provider.addTrackingPoint(gpsPoint);
    }
  }
}
```

#### 4.2.2 结束点强制添加

```dart
Future<void> _stopTracking() async {
  _timer?.cancel();

  // 结束运动前，添加当前位置作为结束点（无论距离上一个点是否超过5米）
  final provider = context.read<ExerciseProvider>();
  if (provider.isTracking && _startPoint != null) {
    final endPoint = GPSPoint(
      latitude: _startPoint!.latitude,
      longitude: _startPoint!.longitude,
      timestamp: DateTime.now(),
    );
    provider.addTrackingPoint(endPoint);
  }

  // 保存运动记录
  await provider.stopTracking();
  // ...
}
```

#### 4.2.3 Haversine 距离计算

```dart
/// 使用 Haversine 公式计算两个 GPS 坐标之间的距离（米）
double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000; // 地球半径（米）
  final double radLat1 = lat1 * pi / 180;
  final double radLat2 = lat2 * pi / 180;
  final double deltaLat = (lat2 - lat1) * pi / 180;
  final double deltaLon = (lon2 - lon1) * pi / 180;

  final double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
      cos(radLat1) * cos(radLat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c;
}
```

### 4.3 控制按钮设计

简化后的控制按钮布局：

| 按钮 | 功能 | 样式 |
|------|------|------|
| 取消 | 放弃运动，返回列表 | 红色图标 |
| 结束 | 保存运动记录，返回列表 | 绿色大图标 |

移除暂停/继续按钮，简化用户操作流程。

### 4.4 实时数据更新

计时器每秒触发 UI 更新，确保显示准确的运动时长：

```dart
_timer = Timer.periodic(const Duration(seconds: 1), (_) {
  if (mounted) {
    // 每次计时器触发都更新 UI
    setState(() {});

    // 更新地图中心（如果有新轨迹点）
    // ...
  }
});
```

### 4.5 实时运动页面重构

```dart
// lib/presentation/screens/exercise/active_workout_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/map_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../providers/exercise_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../providers/map_provider.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final ExerciseType exerciseType;

  const ActiveWorkoutScreen({super.key, required this.exerciseType});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late AMapController _mapController;
  final AMapFlutterLocation _locationPlugin = AMapFlutterLocation();
  Timer? _timer;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  void _initLocation() {
    // 配置高德定位
    AMapFlutterLocation.updatePrivacyShow(true, true);
    AMapFlutterLocation.updatePrivacyAgree(true);

    _locationPlugin.onLocationChanged().listen((location) {
      if (location != null && mounted) {
        final mapProvider = context.read<MapProvider>();
        mapProvider.updateCurrentLocation(
          location.latitude!,
          location.longitude!,
        );
      }
    });
  }

  void _startLocation() {
    // 启动定位
    _locationPlugin.startLocation();
  }

  void _stopLocation() {
    _locationPlugin.stopLocation();
  }

  void _pauseTracking() {
    setState(() => _isPaused = true);
    _timer?.cancel();
    _stopLocation();
  }

  void _resumeTracking() {
    setState(() => _isPaused = false);
    _startLocation();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _stopTracking() async {
    _timer?.cancel();
    _stopLocation();

    final exerciseProvider = context.read<ExerciseProvider>();
    final mapProvider = context.read<MapProvider>();

    // 获取轨迹点
    final trackPoints = mapProvider.trackPoints
        .map((latLng) => GPSPoint(
              latitude: latLng.latitude,
              longitude: latLng.longitude,
              timestamp: DateTime.now(),
            ))
        .toList();

    await exerciseProvider.stopTracking(
      notes: 'GPS点数量: ${trackPoints.length}',
    );

    if (mounted) {
      context.read<StatisticsProvider>().loadStatistics();
      context.pop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locationPlugin.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final exerciseProvider = context.watch<ExerciseProvider>();
    final mapProvider = context.watch<MapProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseType.displayName),
      ),
      body: Column(
        children: [
          // 地图区域 (50%)
          Expanded(
            flex: 1,
            child: AMapView(
              onMapCreated: (controller) {
                _mapController = controller;
                mapProvider.initMapController(controller);
                _startLocation();
              },
              mapType: isDark ? MapType.dark : MapType.standard,
              zoomLevel: MapConstants.defaultZoom,
              myLocationStyle: MyLocationStyle(
                show: true,
                myLocationType: MyLocationType.LOCATION_TYPE_MAP_FOLLOW,
              ),
              // 绘制轨迹线
              polylines: {
                if (mapProvider.trackPoints.isNotEmpty)
                  Polyline(
                    points: mapProvider.trackPoints,
                    color: Color(MapConstants.trackColor),
                    width: MapConstants.trackWidth,
                  ),
              },
            ),
          ),

          // 数据区域 (50%)
          Expanded(
            flex: 1,
            child: _buildDataPanel(exerciseProvider, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildDataPanel(ExerciseProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 计时器
          Text(
            app_date_utils.DateUtils.formatTimer(provider.trackingDuration),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // 统计卡片
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: '距离',
                  value: (provider.trackingDistance / 1000).toStringAsFixed(2),
                  unit: 'km',
                  icon: Icons.straighten_outlined,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: '卡路里',
                  value: provider.trackingCalories.toStringAsFixed(0),
                  unit: 'kcal',
                  icon: Icons.local_fire_department_outlined,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // GPS状态
          Text点: ${provider(
            'GPS.trackingPoints.length}',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const Spacer(),

          // 控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                heroTag: 'cancel',
                onPressed: () {
                  provider.cancelTracking();
                  context.pop();
                },
                backgroundColor: Colors.red,
                child: const Icon(Icons.close),
              ),
              FloatingActionButton.large(
                heroTag: 'pause',
                onPressed: _isPaused ? _resumeTracking : _pauseTracking,
                backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                child: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
              ),
              FloatingActionButton(
                heroTag: 'stop',
                onPressed: _stopTracking,
                backgroundColor: Colors.green,
                child: const Icon(Icons.check),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### 4.2 详情页地图组件

```dart
// lib/presentation/widgets/exercise_map_detail.dart

import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/map_constants.dart';
import '../../core/utils/distance_utils.dart';
import '../../data/models/exercise_model.dart';

class ExerciseMapDetail extends StatelessWidget {
  final ExerciseModel exercise;
  final bool isDark;

  const ExerciseMapDetail({
    super.key,
    required this.exercise,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final gpsPoints = exercise.gpsPoints;
    if (gpsPoints == null || gpsPoints.isEmpty) {
      return _buildNoDataPlaceholder();
    }

    final trackPoints = gpsPoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    // 计算起点和终点
    final startPoint = trackPoints.first;
    final endPoint = trackPoints.last;

    return Column(
      children: [
        // 地图区域
        Expanded(
          child: AMapView(
            initialCameraPosition: CameraPosition(
              target: startPoint,
              zoom: 15,
            ),
            mapType: isDark ? MapType.dark : MapType.standard,
            // 轨迹线
            polylines: {
              Polyline(
                points: trackPoints,
                color: Color(MapConstants.trackColor),
                width: MapConstants.trackWidth,
              ),
            },
            // 标记点
            markers: {
              // 起点标记
              Marker(
                position: startPoint,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
              ),
              // 终点标记
              Marker(
                position: endPoint,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
              ),
            },
          ),
        ),

        // 轨迹统计信息
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatRow('起点', '${startPoint.latitude.toStringAsFixed(4)}, ${startPoint.longitude.toStringAsFixed(4)}'),
              _buildStatRow('终点', '${endPoint.latitude.toStringAsFixed(4)}, ${endPoint.longitude.toStringAsFixed(4)}'),
              _buildStatRow('轨迹点数', '${gpsPoints.length}'),
              _buildStatRow('总距离', '${exercise.distance.toStringAsFixed(2)} km'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('无轨迹数据', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
```

### 4.3 列表页地图缩略图卡片

```dart
// lib/presentation/widgets/exercise_map_card.dart

import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/map_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/exercise_model.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;

class ExerciseMapCard extends StatelessWidget {
  final ExerciseModel exercise;
  final bool isDark;
  final VoidCallback? onTap;

  const ExerciseMapCard({
    super.key,
    required this.exercise,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gpsPoints = exercise.gpsPoints;
    final hasTrack = gpsPoints != null && gpsPoints.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 地图缩略图
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 100,
                height: 100,
                child: hasTrack
                    ? _buildMiniMap(gpsPoints)
                    : _buildPlaceholder(),
              ),
            ),

            // 信息区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 标题行
                    Row(
                      children: [
                        Text(exercise.type.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          exercise.type.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 日期
                    Text(
                      app_date_utils.DateUtils.formatDate(exercise.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 统计
                    Row(
                      children: [
                        _buildStatChip('${exercise.distance.toStringAsFixed(1)} km', isDark),
                        const SizedBox(width: 8),
                        _buildStatChip('${exercise.duration}分钟', isDark),
                        const SizedBox(width: 8),
                        _buildStatChip('${exercise.calories.toInt()} kcal', isDark),
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

  Widget _buildMiniMap(List<GPSPoint> gpsPoints) {
    final trackPoints = gpsPoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return AMapView(
      initialCameraPosition: CameraPosition(
        target: trackPoints.first,
        zoom: 14,
      ),
      mapType: MapType.standard,
      zoomEnabled: false,
      scrollEnabled: false,
      rotateEnabled: false,
      tiltEnabled: false,
      polylines: {
        Polyline(
          points: trackPoints,
          color: Color(MapConstants.trackColor),
          width: 3,
        ),
      },
      markers: {
        Marker(
          position: trackPoints.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        if (trackPoints.length > 1)
          Marker(
            position: trackPoints.last,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: const Icon(Icons.map_outlined, color: Colors.grey),
    );
  }

  Widget _buildStatChip(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        ),
      ),
    );
  }
}
```

---

## 5. 平台配置

### 5.1 Android配置

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
    <!-- 权限 -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    <uses-permission android:name="android.permission.INTERNET" />

    <application>
        <!-- 高德地图Key -->
        <meta-data
            android:name="com.amap.api.v2.apikey"
            android:value="${YOUR_ANDROID_KEY}" />
    </application>
</manifest>
```

### 5.2 iOS配置

```xml
<!-- ios/Runner/Info.plist -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>需要使用您的位置来记录运动轨迹</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>需要使用您的位置来记录运动轨迹</string>
<key>AMapKey</key>
<string>${YOUR_IOS_KEY}</string>
```

### 5.3 iOS Runner配置

在 `ios/Runner/AppDelegate.swift` 中添加：

```swift
import AMapFoundationKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 初始化高德地图
    AMapServices.shared().apiKey = "${YOUR_IOS_KEY}"
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## 6. 依赖注入更新

```dart
// lib/core/di/injection.dart

import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../../data/database/database_helper.dart';
import '../../data/repositories/exercise_repository_impl.dart';
import '../../data/repositories/body_metrics_repository_impl.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../../domain/repositories/body_metrics_repository.dart';
import '../../presentation/providers/exercise_provider.dart';
import '../../presentation/providers/statistics_provider.dart';
import '../../presentation/providers/body_metrics_provider.dart';
import '../../presentation/providers/theme_provider.dart';
import '../../presentation/providers/map_provider.dart';

List<SingleChildWidget> getProviders() {
  return [
    // 现有providers...

    // 新增：地图Provider
    ChangeNotifierProvider<MapProvider>(
      create: (_) => MapProvider(),
    ),
  ];
}
```

---

## 7. 路由更新

```dart
// lib/main.dart - 路由无需修改
// 现有路由结构已支持：/exercise/active, /exercise/:id
```

---

## 8. 实现计划

### 第一阶段：基础集成（1天）

1. 添加依赖到 `pubspec.yaml`
2. 配置 Android/iOS 平台
3. 创建 `MapProvider`
4. 创建地图常量配置

### 第二阶段：实时地图（1天）

1. 重构 `ActiveWorkoutScreen`
2. 集成高德地图显示
3. 绘制实时轨迹线
4. 定位更新监听

### 第三阶段：详情页与列表（1天）

1. 创建 `ExerciseMapDetail` 组件
2. 创建 `ExerciseMapCard` 组件
3. 重构详情页添加地图
4. 重构列表页添加缩略图

---

## 9. 注意事项

1. **API Key管理**：生产环境应使用用户配置或安全存储
2. **定位权限**：需要适配Android 13+的运行时权限
3. **后台定位**：如需后台记录轨迹，需要额外申请权限
4. **电量优化**：合理设置GPS采样频率，避免过度耗电
5. **轨迹数据**：大量GPS点可能影响存储和性能，考虑分表存储

---

*文档版本：v1.0*
*创建日期：2026-03-06*
