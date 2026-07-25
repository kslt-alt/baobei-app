import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/supabase_service.dart';

/// 聊天管理
class ChatProvider extends ChangeNotifier {
  List<ChatMessage> _messages = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<ChatMessage> get messages => _messages;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 加载聊天记录
  Future<void> loadMessages(String userId1, String userId2) async {
    _isLoading = true;
    notifyListeners();

    try {
      _messages = await SupabaseService.instance.getMessages(userId1, userId2);
      _error = null;
    } catch (e) {
      _error = '加载消息失败';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 发送消息
  Future<void> sendMessage(String fromUserId, String toUserId, String content) async {
    if (content.trim().isEmpty) return;

    try {
      await SupabaseService.instance.sendMessage({
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'content': content.trim(),
      });

      // 本地立即显示
      _messages.insert(0, ChatMessage(
        fromUserId: fromUserId,
        toUserId: toUserId,
        content: content.trim(),
      ));
      _error = null;
    } catch (e) {
      _error = '发送失败';
    }
    notifyListeners();
  }

  /// 标记已读
  Future<void> markAsRead(String myId, String fromUserId) async {
    await SupabaseService.instance.markMessagesRead(myId, fromUserId);
    _unreadCount = 0;
    notifyListeners();
  }

  /// 刷新未读数
  Future<void> refreshUnreadCount(String userId) async {
    try {
      _unreadCount = await SupabaseService.instance.getUnreadCount(userId);
      notifyListeners();
    } catch (_) {}
  }

  /// 收到新消息（由订阅触发）
  void onNewMessage(ChatMessage msg) {
    _messages.insert(0, msg);
    _unreadCount++;
    notifyListeners();
  }

  /// 订阅伴侣消息
  void subscribeMessages(String userId) {
    SupabaseService.instance.subscribeMessages(
      userId,
      (msg) => onNewMessage(msg),
    );
  }
}
