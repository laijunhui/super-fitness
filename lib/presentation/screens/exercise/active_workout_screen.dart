import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/map_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../core/utils/distance_utils.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/statistics_provider.dart';

/// 实时运动追踪页
class ActiveWorkoutScreen extends StatefulWidget {
  final ExerciseType exerciseType;

  const ActiveWorkoutScreen({super.key, required this.exerciseType});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  Timer? _timer;
  bool _mapLoadError = false;
  String? _mapErrorMessage;
  bool _isFirstLocationCentered = false;
  bool _isTrackingStopped = false; // 标记是否已停止运动

  // 高德定位
  LatLng? _startPoint; // 运动起点坐标（高德定位）
  bool _isFirstAMapLocationReceived = false; // 是否已收到首次高德定位

  // 地图控制器
  AMapController? _mapController;

  // 默认位置（北京天安门）
  static const LatLng _defaultLocation = LatLng(39.908823, 116.397470);

  // API Key
  final AMapApiKey _apiKey = AMapApiKey(
    androidKey: '485cea207a05dd129e9ac8451dea727b',
    iosKey: 'b5f5ab10966cbf714bfd05ebac9e3816',
  );

  @override
  void initState() {
    super.initState();
    _checkDeviceAndInit();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 检测设备是否为模拟器，如果是则显示警告
  Future<void> _checkDeviceAndInit() async {
    if (!mounted) return;

    // 检测是否为模拟器
    final deviceInfo = DeviceInfoPlugin();
    bool isEmulator = false;

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      // 在模拟器上，brand 通常是 "google" 或 "android"，model 包含 "sdk" 或 "emulator"
      isEmulator = androidInfo.isPhysicalDevice == false;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      isEmulator = !iosInfo.isPhysicalDevice;
    }

    if (isEmulator && mounted) {
      setState(() {
        _mapLoadError = true;
        _mapErrorMessage = '检测到模拟器环境，高德地图需要真机运行';
      });
    }

    // 继续初始化追踪
    if (mounted) {
      _initTracking();
    }
  }

  void _initTracking() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTracking();
    });
  }

  /// 使用 Haversine 公式计算两个 GPS 坐标之间的距离（米）
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // 地球半径（米）
    final double radLat1 = lat1 * 3.14159265358979323846 / 180;
    final double radLat2 = lat2 * 3.14159265358979323846 / 180;
    final double deltaLat = (lat2 - lat1) * 3.14159265358979323846 / 180;
    final double deltaLon = (lon2 - lon1) * 3.14159265358979323846 / 180;

    final double a = _sin(deltaLat / 2) * _sin(deltaLat / 2) +
        _cos(radLat1) * _cos(radLat2) * _sin(deltaLon / 2) * _sin(deltaLon / 2);
    final double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return earthRadius * c;
  }

  // 简化的数学函数，避免 dart:math 导入
  double _sin(double x) {
    return _taylorSin(x);
  }

  double _cos(double x) {
    return _taylorSin(x + 3.14159265358979323846 / 2);
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265358979323846;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265358979323846;
    if (x == 0 && y > 0) return 3.14159265358979323846 / 2;
    if (x == 0 && y < 0) return -3.14159265358979323846 / 2;
    return 0;
  }

  double _atan(double x) {
    if (x.abs() > 1) {
      return (3.14159265358979323846 / 2) - _atan(1 / x);
    }
    double result = 0;
    double term = x;
    for (int n = 0; n < 20; n++) {
      result += term / (2 * n + 1) * (n % 2 == 0 ? 1 : -1);
      term *= x * x;
    }
    return result;
  }

  double _taylorSin(double x) {
    // 归一化到 [-π, π]
    const double pi = 3.14159265358979323846;
    while (x > pi) {
      x -= 2 * pi;
    }
    while (x < -pi) {
      x += 2 * pi;
    }
    double result = 0;
    double term = x;
    for (int n = 0; n < 15; n++) {
      result += term;
      term *= -x * x / ((2 * n + 2) * (2 * n + 3));
    }
    return result;
  }

  Future<void> _startTracking() async {
    if (!mounted) return;

    try {
      final provider = context.read<ExerciseProvider>();
      provider.startTracking(widget.exerciseType);
      provider.checkGpsPermission().then((result) {
        // GPS检查完成
      }).catchError((e) {
        // GPS检查错误
      });

      // 起始位置将通过高德地图的 onLocationChanged 回调获取

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          // 每次计时器触发都更新 UI，以确保计时器显示正确
          setState(() {});

          // 从 provider 获取 GPS 轨迹点
          final provider = context.read<ExerciseProvider>();
          final trackingPoints = provider.trackingPoints;

          if (trackingPoints.isNotEmpty) {
            final newCenter = LatLng(
              trackingPoints.last.latitude,
              trackingPoints.last.longitude,
            );

            // 首次定位时移动地图中心
            if (!_isFirstLocationCentered) {
              _mapController?.moveCamera(
                CameraUpdate.newLatLng(newCenter),
              );
              _isFirstLocationCentered = true;
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Error starting tracking: $e');
    }
  }

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
      debugPrint('DEBUG: End point added: ${_startPoint!.latitude}, ${_startPoint!.longitude}');
    }

    setState(() {
      _isTrackingStopped = true;
    });
    try {
      await provider.stopTracking();
      await context.read<ExerciseProvider>().loadExercises();
      if (mounted) {
        context.read<StatisticsProvider>().loadStatistics();
        context.pop();
      }
    } catch (e) {
      debugPrint('Error stopping tracking: $e');
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final exerciseProvider = context.watch<ExerciseProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseType.displayName),
      ),
      body: Column(
        children: [
          // 地图区域 (约50%)
          Expanded(
            flex: 1,
            child: _buildMapView(exerciseProvider, isDark),
          ),
          // 数据区域 (约50%)
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildDataPanel(exerciseProvider, isDark),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建地图视图
  Widget _buildMapView(ExerciseProvider exerciseProvider, bool isDark) {
    // 如果地图加载失败，显示备用视图
    if (_mapLoadError) {
      return _buildMapFallback(exerciseProvider, isDark);
    }

    // 从 ExerciseProvider 获取轨迹点
    final trackingPoints = exerciseProvider.trackingPoints;
    // 将 GPSPoint 转换为 LatLng
    final trackLatLngList = trackingPoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    // 当前位置 - 优先使用高德定位点，其次使用轨迹点
    LatLng currentCenter = _defaultLocation;
    if (_startPoint != null) {
      currentCenter = _startPoint!;
    } else if (trackLatLngList.isNotEmpty) {
      currentCenter = trackLatLngList.last;
    }

    // 构建轨迹线 - 只有多于1个点时才显示线
    List<Polyline> polylines = [];
    if (trackLatLngList.length > 1) {
      polylines.add(Polyline(
        points: trackLatLngList,
        color: Color(MapConstants.trackColorValue),
        width: MapConstants.trackWidth,
      ));
    }

    // 构建标记点
    final markers = <Marker>[];
    // 起点 - 只在高德定位坐标完成后才显示（_startPoint 不为 null）
    if (_startPoint != null) {
      markers.add(Marker(
        position: _startPoint!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        anchor: const Offset(0.5, 0.5),
      ));
    }
    // 终点 - 只有结束运动后才显示
    if (_isTrackingStopped && trackLatLngList.length > 1) {
      markers.add(Marker(
        position: trackLatLngList.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        anchor: const Offset(0.5, 0.5),
      ));
    }

    debugPrint('DEBUG: currentCenter = ${currentCenter.latitude}, ${currentCenter.longitude}');
    debugPrint('DEBUG: trackLatLngList.length = ${trackLatLngList.length}');

    return Stack(
      children: [
        AMapWidget(
          key: ValueKey(currentCenter.toString()), // 强制重建
          apiKey: _apiKey,
          initialCameraPosition: CameraPosition(
            target: currentCenter,
            zoom: MapConstants.defaultZoom,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            debugPrint('DEBUG: onMapCreated called');
          },
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
              debugPrint('DEBUG: AMap first location received: ${point.latitude}, ${point.longitude}');

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
                    debugPrint('DEBUG: Abnormal point detected and removed! prevDistance: ${prevDistance.toStringAsFixed(1)}m, currentDistance: ${distance.toStringAsFixed(1)}m');
                    return; // 跳过这个异常点
                  }
                }

                final gpsPoint = GPSPoint(
                  latitude: point.latitude,
                  longitude: point.longitude,
                  timestamp: DateTime.now(),
                );
                provider.addTrackingPoint(gpsPoint);
                debugPrint('DEBUG: New track point added, distance: ${distance.toStringAsFixed(1)}m');
              }
            }
          },
          // 启用高德定位蓝点（第一个参数true启用）
          myLocationStyleOptions: MyLocationStyleOptions(
            true, // 启用定位蓝点
            circleFillColor: Colors.blue.withOpacity(0.3),
            circleStrokeColor: Colors.blue,
          ),
          polylines: Set<Polyline>.of(polylines),
          markers: Set<Marker>.of(markers),
          // 禁用POI点击，避免出现地点选择图标
          touchPoiEnabled: false,
        ),
        // 调试：打印 mapController 状态
        if (_mapController != null)
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red,
              child: Text(
                'Controller: OK\nPoints: ${trackLatLngList.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        // 定位按钮
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: isDark ? Colors.grey[800] : Colors.white,
            onPressed: () {
              // 移动到当前位置
              if (trackLatLngList.isNotEmpty) {
                _mapController?.moveCamera(
                  CameraUpdate.newLatLng(trackLatLngList.last),
                );
              } else if (_startPoint != null) {
                _mapController?.moveCamera(
                  CameraUpdate.newLatLng(_startPoint!),
                );
              }
            },
            child: Icon(
              Icons.my_location,
              color: isDark ? Colors.white : Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  /// 地图加载失败时的备用视图
  Widget _buildMapFallback(ExerciseProvider exerciseProvider, bool isDark) {
    return Container(
      color: isDark ? Colors.grey[900] : Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '地图加载失败',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _mapErrorMessage ?? '可能是设备不支持OpenGL或模拟器环境限制',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _mapLoadError = false;
                  _mapErrorMessage = null;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建数据面板
  Widget _buildDataPanel(ExerciseProvider exerciseProvider, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 计时器
        Text(
          app_date_utils.DateUtils.formatTimer(exerciseProvider.trackingDuration),
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 24),

        // GPS状态
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: exerciseProvider.gpsEnabled
                ? Colors.green.withOpacity(0.2)
                : Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                exerciseProvider.gpsEnabled ? Icons.gps_fixed : Icons.gps_off,
                size: 16,
                color: exerciseProvider.gpsEnabled ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                exerciseProvider.gpsEnabled
                    ? 'GPS追踪中 (${exerciseProvider.trackingPoints.length}点)'
                    : 'GPS未开启',
                style: TextStyle(
                  color: exerciseProvider.gpsEnabled ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (exerciseProvider.gpsError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              exerciseProvider.gpsError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 16),

        // 统计卡片
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: '距离',
                value: (exerciseProvider.trackingDistance / 1000).toStringAsFixed(2),
                unit: 'km',
                icon: Icons.straighten_outlined,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: '卡路里',
                value: exerciseProvider.trackingCalories.toStringAsFixed(0),
                unit: 'kcal',
                icon: Icons.local_fire_department_outlined,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const Spacer(),

        // 控制按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 取消按钮
            FloatingActionButton(
              heroTag: 'cancel',
              onPressed: () {
                exerciseProvider.cancelTracking();
                context.pop();
              },
              backgroundColor: Colors.red,
              child: const Icon(Icons.close),
            ),
            // 结束运动按钮
            FloatingActionButton.large(
              heroTag: 'stop',
              onPressed: _stopTracking,
              backgroundColor: Colors.green,
              child: const Icon(Icons.check),
            ),
          ],
        ),
      ],
    );
  }
}
