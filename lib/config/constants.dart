/// 应用常量配置
class AppConstants {
  AppConstants._();

  /// Supabase 配置（用户需替换为自己的）
  /// 注册地址：https://supabase.com
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';

  /// 位置上报间隔（秒）
  static const int locationUpdateInterval = 30;

  /// 历史轨迹保留天数
  static const int historyRetentionDays = 7;

  /// 配对码长度
  static const int pairingCodeLength = 6;

  /// 预定义状态列表
  static const List<Map<String, String>> predefinedStatuses = [
    {'emoji': '🚶', 'label': '出门了', 'value': 'out'},
    {'emoji': '🏢', 'label': '到公司了', 'value': 'at_work'},
    {'emoji': '🏠', 'label': '到家了', 'value': 'at_home'},
    {'emoji': '🚗', 'label': '回家路上', 'value': 'going_home'},
    {'emoji': '🍽️', 'label': '在吃饭', 'value': 'eating'},
    {'emoji': '🛒', 'label': '在逛街', 'value': 'shopping'},
    {'emoji': '💪', 'label': '在运动', 'value': 'working_out'},
    {'emoji': '🌙', 'label': '睡觉了', 'value': 'sleeping'},
    {'emoji': '📵', 'label': '学习中', 'value': 'studying'},
    {'emoji': '💼', 'label': '在忙', 'value': 'busy'},
  ];
}
