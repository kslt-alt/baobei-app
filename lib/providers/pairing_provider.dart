import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

/// 配对管理
class PairingProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 使用配对码配对
  Future<bool> pairWithCode(String userId, String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 查找配对码对应的用户
      final partner = await SupabaseService.instance.findUserByPairingCode(code);
      if (partner == null) {
        _error = '配对码无效，请检查后重试';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (partner.id == userId) {
        _error = '不能和自己配对哦～';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (partner.pairedWith != null) {
        _error = '对方已经和其他人配对啦';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 双向绑定
      await SupabaseService.instance.updateProfile(userId, {'paired_with': partner.id});
      await SupabaseService.instance.updateProfile(partner.id, {'paired_with': userId});

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = '配对失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 解绑配对
  Future<bool> unpair(String userId, String partnerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseService.instance.updateProfile(userId, {'paired_with': null});
      await SupabaseService.instance.updateProfile(partnerId, {'paired_with': null});
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = '解绑失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
