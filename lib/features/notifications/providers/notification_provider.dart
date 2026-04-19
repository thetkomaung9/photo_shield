import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/notification_item.dart';

class NotificationsNotifier extends AsyncNotifier<List<NotificationItem>> {
  @override
  Future<List<NotificationItem>> build() async {
    final res = await ApiService().dio.get('/notifications');
    final list = res.data['notifications'] as List;
    return list.map((e) => NotificationItem.fromJson(e)).toList();
  }

  Future<void> markRead(String id) async {
    await ApiService().dio.patch('/notifications/$id/read');
    ref.invalidateSelf();
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationItem>>(
      NotificationsNotifier.new,
    );
