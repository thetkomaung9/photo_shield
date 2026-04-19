class NotificationItem {
  final String notificationId;
  final String type;
  final String message;
  final String? detectionId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.notificationId,
    required this.type,
    required this.message,
    this.detectionId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        notificationId: json['notification_id'],
        type: json['type'],
        message: json['message'],
        detectionId: json['detection_id'],
        isRead: json['is_read'] ?? false,
        createdAt: DateTime.parse(json['created_at']),
      );
}
