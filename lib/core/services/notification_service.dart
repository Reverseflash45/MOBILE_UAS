import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _notificationChannel;

  Future<void> initializeNotificationListener({
    required String currentUserId,
    required Function(Map<String, dynamic> payload) onNewNotification,
  }) async {
    await _notificationChannel?.unsubscribe();

    _notificationChannel = _supabase
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId,
          ),
          callback: (PostgresChangePayload payload) {
            if (payload.newRecord.isNotEmpty) {
              onNewNotification(payload.newRecord);
            }
          },
        );

    await _notificationChannel?.subscribe();
  }

  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (_) {}
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String ticketId,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'ticket_id': ticketId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _notificationChannel?.unsubscribe();
  }
}