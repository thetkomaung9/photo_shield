class User {
  final String userId;
  final String name;
  final String email;
  final bool notificationEnabled;
  final DateTime createdAt;

  const User({
    required this.userId,
    required this.name,
    required this.email,
    required this.notificationEnabled,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    userId: json['user_id'],
    name: json['name'],
    email: json['email'],
    notificationEnabled: json['notification_enabled'] ?? true,
    createdAt: DateTime.parse(json['created_at']),
  );
}
