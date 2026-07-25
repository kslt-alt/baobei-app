import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/location_record.dart';
import 'supabase_service.dart';

/// 定位服务 - 负责前台 + 后台位置采集
class LocationService {
  static final LocationService _instance = LocationService._();
  factory LocationService() => _instance;
  LocationService._();

  bool _isRunning = false;
  Timer? _uploadTimer;
  Position? _lastPosition;

  /// 请求位置权限
  Future<bool> requestPermissions() async {
    // 前台定位权限
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    // Android 后台定位权限
    permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// 获取当前位置
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        // 使用默认精度设置
      );
    } catch (e) {
      return null;
    }
  }

  /// 获取电量信息（通过位置服务附带）
  Future<Map<String, dynamic>> getBatteryInfo() async {
    // Geolocator 不直接提供电量
    // 这里通过设备信息获取（简化处理）
    // 在 Android 上可以通过 MethodChannel 获取真实电量
    return {
      'battery_level': 100,
      'is_charging': false,
    };
  }

  /// 开始周期性上传位置
  Future<void> startLocationUpload(String userId) async {
    if (_isRunning) return;
    _isRunning = true;

    // 立即上传一次
    await _uploadLocation(userId);

    // 定时上传
    _uploadTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) async {
        if (!_isRunning) return;
        await _uploadLocation(userId);
      },
    );
  }

  /// 停止上传
  void stopLocationUpload() {
    _isRunning = false;
    _uploadTimer?.cancel();
    _uploadTimer = null;
  }

  /// 上传一次位置到 Supabase
  Future<void> _uploadLocation(String userId) async {
    try {
      final pos = await getCurrentPosition();
      if (pos == null) return;

      _lastPosition = pos;

      final record = LocationRecord(
        userId: userId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        altitude: pos.altitude,
        speed: pos.speed,
      );

      await SupabaseService.instance.uploadLocation(record.toJson());
    } catch (e) {
      // 静默失败，下次重试
    }
  }

  /// 计算两点距离（米）
  static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// 获取最后已知位置
  Position? get lastPosition => _lastPosition;
}
