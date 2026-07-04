import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final notifs = await NotificationService().getNotifications(user.id);
    if (mounted) {
      setState(() {
        _notifications = notifs;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String id) async {
    await NotificationService().markAsRead(id);
    _fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('Belum ada notifikasi baru'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final isRead = notif['is_read'] ?? false;

                    return Card(
                      color: isRead ? null : Colors.blue.withOpacity(0.05),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          Icons.notifications,
                          color: isRead ? Colors.grey : Colors.blue,
                        ),
                        title: Text(
                          notif['title'] ?? 'Pemberitahuan',
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(notif['message'] ?? ''),
                        trailing: isRead
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.check_circle_outline),
                                onPressed: () => _markAsRead(notif['id'].toString()),
                              ),
                        onTap: () {
                          if (!isRead) _markAsRead(notif['id'].toString());
                        },
                      ),
                    );
                  },
                ),
    );
  }
}