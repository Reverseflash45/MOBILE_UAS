import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  RealtimeChannel? _notificationChannel;

  Future<void> _showLocalNotification(String title, String body) async {
    // Cek dulu settingan user dari memori HP
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('notifications_enabled') ?? true;

    // Kalau dimatiin (false), fungsi ini langsung berhenti dan pop-up gak akan muncul
    if (!isEnabled) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'ticket_updates_channel',
      'Ticket Updates',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
    );
  }

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
              final newNotif = payload.newRecord;
              onNewNotification(newNotif);
              _showLocalNotification(
                newNotif['title']?.toString() ?? 'Pemberitahuan Baru',
                newNotif['message']?.toString() ?? 'Ada pembaruan pada tiket Anda.',
              );
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