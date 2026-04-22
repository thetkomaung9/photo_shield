import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/mock_data.dart';
import '../../../shared/models/notification_item.dart';

/// 알림 목록 프로바이더.
///
/// 데모 모드 전용 — [MockData.notifications] 를 반환하며, 읽음 처리도
/// 메모리 상에서만 반영된다.
class NotificationsNotifier extends AsyncNotifier<List<NotificationItem>> {
  final Set<String> _readIds = {};

  @override
  Future<List<NotificationItem>> build() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return MockData.notifications.map((n) {
      if (_readIds.contains(n.notificationId)) {
        return NotificationItem(
          notificationId: n.notificationId,
          type: n.type,
          message: n.message,
          detectionId: n.detectionId,
          isRead: true,
          createdAt: n.createdAt,
        );
      }
      return n;
    }).toList();
  }

  Future<void> markRead(String id) async {
    _readIds.add(id);
    ref.invalidateSelf();
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationItem>>(
  NotificationsNotifier.new,
);
