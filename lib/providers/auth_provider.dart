import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

/// 认证状态管理
class AuthProvider extends ChangeNotifier {
  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _profile != null;
  bool get isPaired => _profile?.pairedWith != null;
  String? get error => _error;
  String? get userId => _profile?.id;
  String? get pairingCode => _profile?.pairingCode;

  /// 初始化 - 检查是否已登录
  Future<void> init() async {
    final supabase = SupabaseService.instance;
    final user = supabase.currentUser;
    if (user != null) {
      await loadProfile(user.id);
    }
  }

  /// 加载用户档案
  Future<void> loadProfile(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await SupabaseService.instance.getProfile(userId);
      _error = null;
    } catch (e) {
      _error = '加载用户信息失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 注册
  Future<bool> signUp(String email, String password, String displayName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await SupabaseService.instance.signUp(email, password, displayName);
      if (response.user != null) {
        await loadProfile(response.user!.id);
        return true;
      }
      _error = '注册失败，请重试';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 登录
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await SupabaseService.instance.signIn(email, password);
      if (response.user != null) {
        await loadProfile(response.user!.id);
        return true;
      }
      _error = '账号或密码错误';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 退出登录
  Future<void> signOut() async {
    await SupabaseService.instance.signOut();
    _profile = null;
    notifyListeners();
  }

  /// 执行配对
  Future<bool> pairWith(String code) async {
    if (_profile == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final partner = await SupabaseService.instance.findUserByPairingCode(code);
      if (partner == null) {
        _error = '配对码无效，请检查';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (partner.id == _profile!.id) {
        _error = '不能和自己配对';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (partner.pairedWith != null) {
        _error = '对方已完成配对';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 双向绑定
      await SupabaseService.instance.updateProfile(_profile!.id, {'paired_with': partner.id});
      await SupabaseService.instance.updateProfile(partner.id, {'paired_with': _profile!.id});

      await loadProfile(_profile!.id);
      return true;
    } catch (e) {
      _error = '配对失败: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 刷新档案
  Future<void> refreshProfile() async {
    if (_profile != null) {
      await loadProfile(_profile!.id);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
