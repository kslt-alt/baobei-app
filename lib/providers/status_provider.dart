import 'package:flutter/material.dart';
import '../models/status_record.dart';
import '../services/supabase_service.dart';

/// 状态报备管理
class StatusProvider extends ChangeNotifier {
  StatusRecord? _myStatus;
  StatusRecord? _partnerStatus;
  bool _isLoading = false;
  String? _latestStatusValue;

  StatusRecord? get myStatus => _myStatus;
  StatusRecord? get partnerStatus => _partnerStatus;
  bool get isLoading => _isLoading;
  String? get latestStatusValue => _latestStatusValue;

  /// 发布状态
  Future<void> postStatus(String userId, String status, {String? message}) async {
    _latestStatusValue = status;
    notifyListeners();

    try {
      await SupabaseService.instance.postStatus({
        'user_id': userId,
        'status': status,
        'message': message,
      });

      _myStatus = StatusRecord(
        userId: userId,
        status: status,
        message: message,
      );
    } catch (e) {
      // 静默
    }
    notifyListeners();
  }

  /// 获取双方最新状态
  Future<void> fetchBothStatuses(String myId, String? partnerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _myStatus = await SupabaseService.instance.getLatestStatus(myId);
      if (partnerId != null) {
        _partnerStatus = await SupabaseService.instance.getLatestStatus(partnerId);
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  /// 订阅伴侣状态变化
  void subscribePartnerStatus(String partnerId) {
    SupabaseService.instance.subscribeStatus(
      partnerId,
      (status) {
        _partnerStatus = status;
        notifyListeners();
      },
    );
  }
}
