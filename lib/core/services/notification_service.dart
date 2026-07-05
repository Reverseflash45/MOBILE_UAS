import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  RealtimeChannel? _notificationChannel;

  Future<void> _showLocalNotification(
    String title,
    String body,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final isEnabled =
          prefs.getBool('notifications_enabled') ?? true;

      if (!isEnabled) return;

      const androidDetails = AndroidNotificationDetails(
        'ticket_updates_channel',
        'Ticket Updates',
        channelDescription:
            'Notifikasi perubahan dan pembaruan status tiket',
        importance: Importance.max,
        priority: Priority.high,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        notificationDetails,
      );
    } catch (e, stackTrace) {
      debugPrint('Gagal menampilkan notifikasi lokal: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> initializeNotificationListener({
    required String currentUserId,
    required Function(Map<String, dynamic> payload)
        onNewNotification,
  }) async {
    try {
      await _notificationChannel?.unsubscribe();

      _notificationChannel = _supabase
          .channel('notifications_$currentUserId')
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
              final newRecord = payload.newRecord;

              if (newRecord.isEmpty) return;

              final notification =
                  Map<String, dynamic>.from(newRecord);

              onNewNotification(notification);

              _showLocalNotification(
                notification['title']?.toString() ??
                    'Pemberitahuan Baru',
                notification['message']?.toString() ??
                    'Ada pembaruan pada tiket Anda.',
              );
            },
          );

      await _notificationChannel?.subscribe();
    } catch (e, stackTrace) {
      debugPrint('Gagal mengaktifkan listener notifikasi: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      debugPrint('Gagal mengambil notifikasi: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final currentUserId =
        _supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      throw Exception('Pengguna belum login');
    }

    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
          })
          .eq('id', notificationId)
          .eq('user_id', currentUserId);
    } catch (e, stackTrace) {
      debugPrint('Gagal menandai notifikasi: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    final currentUserId =
        _supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      throw Exception('Pengguna belum login');
    }

    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
          })
          .eq('user_id', currentUserId)
          .eq('is_read', false);
    } catch (e, stackTrace) {
      debugPrint('Gagal menandai semua notifikasi: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String ticketId,
    String type = 'general',
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'ticket_id': ticketId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': false,
      });
    } catch (e, stackTrace) {
      debugPrint('Gagal membuat notifikasi: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _notificationChannel?.unsubscribe();
    _notificationChannel = null;
  }
}