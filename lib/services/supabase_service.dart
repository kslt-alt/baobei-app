import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../models/user_profile.dart';
import '../models/location_record.dart';
import '../models/status_record.dart';
import '../models/chat_message.dart';

/// Supabase 单例服务
/// 使用前必须先调用 initialize()
class SupabaseService {
  static SupabaseService? _instance;
  late final SupabaseClient _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  SupabaseClient get client => _client;
  User? get currentUser => _client.auth.currentUser;

  /// 初始化 Supabase 连接
  Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  /// ========== 鉴权 ==========

  /// 注册新用户（手机号/用户名 + 密码）
  Future<AuthResponse> signUp(String email, String password, String displayName) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName, 'username': email},
    );
    if (response.user != null) {
      // 创建用户档案
      await _client.from('profiles').upsert({
        'id': response.user!.id,
        'username': email,
        'display_name': displayName,
      });
    }
    return response;
  }

  /// 登录
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// 退出登录
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// ========== 用户档案 ==========

  /// 获取用户档案
  Future<UserProfile?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return UserProfile.fromJson(response);
  }

  /// 更新档案
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _client.from('profiles').update(data).eq('id', userId);
  }

  /// 通过配对码查找用户
  Future<UserProfile?> findUserByPairingCode(String code) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('pairing_code', code.toUpperCase())
        .maybeSingle();
    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  /// ========== 位置 ==========

  /// 上传位置
  Future<void> uploadLocation(Map<String, dynamic> locationData) async {
    await _client.from('locations').insert(locationData);
  }

  /// 获取某个用户最近的位置
  Future<LocationRecord?> getLatestLocation(String userId) async {
    final response = await _client
        .from('locations')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (response == null) return null;
    return LocationRecord.fromJson(response);
  }

  /// 获取某用户某段时间的轨迹
  Future<List<LocationRecord>> getLocationHistory(
    String userId, {
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final response = await _client
        .from('locations')
        .select()
        .eq('user_id', userId)
        .gte('created_at', startTime.toIso8601String())
        .lte('created_at', endTime.toIso8601String())
        .order('created_at', ascending: true);
    return (response as List).map((j) => LocationRecord.fromJson(j)).toList();
  }

  /// ========== 状态 ==========

  /// 发布状态
  Future<void> postStatus(Map<String, dynamic> statusData) async {
    await _client.from('statuses').insert(statusData);
  }

  /// 获取最近的状态
  Future<StatusRecord?> getLatestStatus(String userId) async {
    final response = await _client
        .from('statuses')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (response == null) return null;
    return StatusRecord.fromJson(response);
  }

  /// ========== 消息 ==========

  /// 发送消息
  Future<void> sendMessage(Map<String, dynamic> msgData) async {
    await _client.from('messages').insert(msgData);
  }

  /// 获取两人之间的聊天记录
  Future<List<ChatMessage>> getMessages(String userId1, String userId2, {int limit = 50}) async {
    // 查询双方互发的消息
    final response = await _client
        .from('messages')
        .select()
        .or('from_user_id.eq.$userId1,from_user_id.eq.$userId2')
        .or('to_user_id.eq.$userId1,to_user_id.eq.$userId2')
        .order('created_at', ascending: false)
        .limit(limit);
    return (response as List).map((j) => ChatMessage.fromJson(j)).toList();
  }

  /// 标记消息已读
  Future<void> markMessagesRead(String userId, String fromUserId) async {
    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('to_user_id', userId)
        .eq('from_user_id', fromUserId)
        .eq('is_read', false);
  }

  /// 获取未读消息数
  Future<int> getUnreadCount(String userId) async {
    final response = await _client
        .from('messages')
        .select('id')
        .eq('to_user_id', userId)
        .eq('is_read', false);
    return (response as List).length;
  }

  /// ========== 实时订阅 ==========

  /// 订阅位置变化
  RealtimeChannel subscribeLocations(
    String pairedUserId,
    Function(LocationRecord) onUpdate,
  ) {
    return _client
        .channel('location-channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          table: 'locations',
          schema: 'public',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: pairedUserId),
          callback: (payload) {
            final loc = LocationRecord.fromJson(payload.newRecord!);
            onUpdate(loc);
          },
        )
        .subscribe();
  }

  /// 订阅状态变化
  RealtimeChannel subscribeStatus(
    String pairedUserId,
    Function(StatusRecord) onUpdate,
  ) {
    return _client
        .channel('status-channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          table: 'statuses',
          schema: 'public',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: pairedUserId),
          callback: (payload) {
            final status = StatusRecord.fromJson(payload.newRecord!);
            onUpdate(status);
          },
        )
        .subscribe();
  }

  /// 订阅新消息
  RealtimeChannel subscribeMessages(
    String userId,
    Function(ChatMessage) onMessage,
  ) {
    return _client
        .channel('message-channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          table: 'messages',
          schema: 'public',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'to_user_id', value: userId),
          callback: (payload) {
            final msg = ChatMessage.fromJson(payload.newRecord!);
            onMessage(msg);
          },
        )
        .subscribe();
  }
}
