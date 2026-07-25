/// 聊天消息模型
class ChatMessage {
  final int? id;
  final String fromUserId;
  final String toUserId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.content,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int?,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      content: json['content'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'content': content,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
