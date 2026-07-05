import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() =>
      _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService =
      NotificationService();

  List<Map<String, dynamic>> _notifications = [];

  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Pengguna belum login');
      }

      final notifications =
          await _notificationService.getNotifications(user.id);

      if (!mounted) return;

      setState(() {
        _notifications =
            List<Map<String, dynamic>>.from(notifications);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _notificationService.markAsRead(notificationId);

      if (!mounted) return;

      setState(() {
        final index = _notifications.indexWhere(
          (notification) =>
              notification['id'].toString() == notificationId,
        );

        if (index != -1) {
          _notifications[index]['is_read'] = true;
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membaca notifikasi: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return '';
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) {
      return '';
    }

    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year;
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  IconData _getNotificationIcon(Map<String, dynamic> notification) {
    final type =
        notification['type']?.toString().toLowerCase() ?? '';

    switch (type) {
      case 'ticket_created':
        return Icons.confirmation_number_outlined;

      case 'ticket_assigned':
        return Icons.assignment_ind_outlined;

      case 'ticket_progress':
        return Icons.support_agent;

      case 'ticket_closed':
        return Icons.check_circle_outline;

      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(
    Map<String, dynamic> notification,
  ) {
    final type =
        notification['type']?.toString().toLowerCase() ?? '';

    switch (type) {
      case 'ticket_created':
        return Colors.blue;

      case 'ticket_assigned':
        return Colors.orange;

      case 'ticket_progress':
        return Colors.purple;

      case 'ticket_closed':
        return Colors.green;

      default:
        return Colors.indigo;
    }
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 180),
        Icon(
          Icons.notifications_none,
          size: 72,
          color: Colors.grey,
        ),
        SizedBox(height: 16),
        Text(
          'Belum ada notifikasi',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Notifikasi perubahan status tiket akan muncul di sini.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 180),
        const Icon(
          Icons.error_outline,
          size: 72,
          color: Colors.red,
        ),
        const SizedBox(height: 16),
        const Text(
          'Gagal memuat notifikasi',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage ?? 'Terjadi kesalahan',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _fetchNotifications,
          child: const Text('Coba Lagi'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchNotifications,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _errorMessage != null
                ? _buildErrorState()
                : _notifications.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification =
                              _notifications[index];

                          final bool isRead =
                              notification['is_read'] == true;

                          final color =
                              _getNotificationColor(notification);

                          final title =
                              notification['title']?.toString() ??
                                  'Pemberitahuan';

                          final message =
                              notification['message']
                                      ?.toString() ??
                                  '';

                          final createdAt = _formatDate(
                            notification['created_at'],
                          );

                          return Card(
                            color: isRead
                                ? null
                                : color.withOpacity(0.08),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    color.withOpacity(0.12),
                                child: Icon(
                                  _getNotificationIcon(
                                    notification,
                                  ),
                                  color: color,
                                ),
                              ),
                              title: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (message.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(message),
                                  ],
                                  if (createdAt.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      createdAt,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: isRead
                                  ? null
                                  : IconButton(
                                      tooltip:
                                          'Tandai sudah dibaca',
                                      icon: Icon(
                                        Icons
                                            .check_circle_outline,
                                        color: color,
                                      ),
                                      onPressed: _isProcessing
                                          ? null
                                          : () => _markAsRead(
                                                notification['id']
                                                    .toString(),
                                              ),
                                    ),
                              onTap: () {
                                if (!isRead) {
                                  _markAsRead(
                                    notification['id']
                                        .toString(),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}