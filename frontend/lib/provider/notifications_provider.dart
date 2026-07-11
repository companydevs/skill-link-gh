import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repository/notifications_repository.dart';
import '../domain/models/notification_model.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository();
});

final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((
  ref,
) {
  final repository = ref.watch(notificationsRepositoryProvider);
  return repository.notificationsStream();
});

final unreadCountStreamProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  return repository.unreadCountStream();
});
