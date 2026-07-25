import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/location_record.dart';
import '../services/supabase_service.dart';
import '../services/location_service.dart';

/// 位置数据状态管理
class LocationProvider extends ChangeNotifier {
  LocationRecord? _myLocation;
  LocationRecord? _partnerLocation;
  List<LocationRecord> _history = [];
  bool _isLoading = false;
  bool _isSharing = false;
  String? _error;
  StreamSubscription<RealtimeSubscription>? _subscription;

  LocationRecord? get myLocation => _myLocation;
  LocationRecord? get partnerLocation => _partnerLocation;
  List<LocationRecord> get history => _history;
  bool get isLoading => _isLoading;
  bool get isSharing => _isSharing;
  String? get error => _error;

  /// 开始共享位置
  Future<void> startSharing(String userId) async {
    _isSharing = true;
    notifyListeners();

    await LocationService().startLocationUpload(userId);

    // 立即获取一次当前位置
    final pos = await LocationService().getCurrentPosition();
    if (pos != null) {
      _myLocation = LocationRecord(
        userId: userId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
      );
      notifyListeners();
    }
  }

  /// 停止共享位置
  void stopSharing() {
    _isSharing = false;
    LocationService().stopLocationUpload();
    notifyListeners();
  }

  /// 获取伴侣最新位置
  Future<void> fetchPartnerLocation(String partnerId) async {
    try {
      final loc = await SupabaseService.instance.getLatestLocation(partnerId);
      if (loc != null) {
        _partnerLocation = loc;
        notifyListeners();
      }
    } catch (e) {
      // 静默
    }
  }

  /// 获取历史轨迹
  Future<void> fetchHistory(String userId, {required DateTime date}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(hours: 23, minutes: 59, seconds: 59));

      _history = await SupabaseService.instance.getLocationHistory(
        userId,
        startTime: startOfDay,
        endTime: endOfDay,
      );
      _error = null;
    } catch (e) {
      _error = '加载轨迹失败';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 订阅伴侣位置变化
  void subscribePartnerLocation(String partnerId) {
    SupabaseService.instance.subscribeLocations(
      partnerId,
      (location) {
        _partnerLocation = location;
        notifyListeners();
      },
    );
  }

  /// 取消订阅
  void disposeSubscriptions() {
    _subscription?.cancel();
  }

  /// 获取两人之间的距离（米）
  double? get distanceToPartner {
    if (_myLocation == null || _partnerLocation == null) return null;
    return LocationService.calculateDistance(
      _myLocation!.latitude, _myLocation!.longitude,
      _partnerLocation!.latitude, _partnerLocation!.longitude,
    );
  }
}
