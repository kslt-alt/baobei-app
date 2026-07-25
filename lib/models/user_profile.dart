/// 用户档案模型
class UserProfile {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? pairingCode;
  final String? pairedWith;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.pairingCode,
    this.pairedWith,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      pairingCode: json['pairing_code'] as String?,
      pairedWith: json['paired_with'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'pairing_code': pairingCode,
      'paired_with': pairedWith,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    String? pairingCode,
    String? pairedWith,
  }) {
    return UserProfile(
      id: id,
      username: username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      pairingCode: pairingCode ?? this.pairingCode,
      pairedWith: pairedWith ?? this.pairedWith,
      createdAt: createdAt,
    );
  }
}
