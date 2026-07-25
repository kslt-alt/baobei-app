/// 报备状态记录模型
class StatusRecord {
  final int? id;
  final String userId;
  final String status;  // 预定义状态值: out, at_work, at_home, going_home, etc.
  final String? message; // 自定义消息
  final DateTime createdAt;

  StatusRecord({
    this.id,
    required this.userId,
    required this.status,
    this.message,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 获取状态的 emoji 展示
  String get emoji {
    const statusEmojis = {
      'out': '🚶',
      'at_work': '🏢',
      'at_home': '🏠',
      'going_home': '🚗',
      'eating': '🍽️',
      'shopping': '🛒',
      'working_out': '💪',
      'sleeping': '🌙',
      'studying': '📵',
      'busy': '💼',
    };
    return statusEmojis[status] ?? '💬';
  }

  /// 获取状态的中文标签
  String get label {
    const statusLabels = {
      'out': '出门了',
      'at_work': '到公司了',
      'at_home': '到家了',
      'going_home': '回家路上',
      'eating': '在吃饭',
      'shopping': '在逛街',
      'working_out': '在运动',
      'sleeping': '睡觉了',
      'studying': '学习中',
      'busy': '在忙',
    };
    return statusLabels[status] ?? message ?? '未知';
  }

  factory StatusRecord.fromJson(Map<String, dynamic> json) {
    return StatusRecord(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      status: json['status'] as String? ?? '',
      message: json['message'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'status': status,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
