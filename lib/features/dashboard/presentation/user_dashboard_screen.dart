import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/notification_service.dart';
import '../../dashboard/presentation/widgets/dashboard_statistic_widget.dart';

class UserDashboardScreen
    extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  ConsumerState<UserDashboardScreen> createState() =>
      _UserDashboardScreenState();
}

class _UserDashboardScreenState
    extends ConsumerState<UserDashboardScreen> {
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    final userId =
        Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) return;

    await _loadUnreadNotifications(userId);

    await NotificationService()
        .initializeNotificationListener(
      currentUserId: userId,
      onNewNotification: (payload) {
        if (!mounted) return;

        setState(() {
          _unreadNotifications++;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              payload['title']?.toString() ??
                  'Status tiket diperbarui',
            ),
            action: SnackBarAction(
              label: 'Buka',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRouter.notificationRoute,
                ).then((_) {
                  _loadUnreadNotifications(userId);
                });
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadUnreadNotifications(
    String userId,
  ) async {
    try {
      final notifications =
          await NotificationService()
              .getNotifications(userId);

      final unreadCount = notifications
          .where(
            (notification) =>
                notification['is_read'] != true,
          )
          .length;

      if (!mounted) return;

      setState(() {
        _unreadNotifications = unreadCount;
      });
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    final userId =
        Supabase.instance.client.auth.currentUser?.id;

    await Navigator.pushNamed(
      context,
      AppRouter.notificationRoute,
    );

    if (userId != null) {
      await _loadUnreadNotifications(userId);
    }
  }

  Widget _buildNotificationIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_none),
        if (_unreadNotifications > 0)
          Positioned(
            right: -5,
            top: -5,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _unreadNotifications > 99
                    ? '99+'
                    : _unreadNotifications.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 28,
            color: Colors.indigo,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  void dispose() {
    NotificationService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Pengguna'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRouter.profileRoute,
              );
            },
          ),
          IconButton(
            icon: _buildNotificationIcon(),
            onPressed: _openNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRouter.settingRoute,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const DashboardStatisticWidget(),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(
              bottom: 12,
              left: 4,
            ),
            child: Text(
              'Menu Utama',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          _buildMenuCard(
            icon: Icons.history,
            title: 'Riwayat Tiket',
            subtitle:
                'Pantau status laporan Anda',
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRouter.listTicketRoute,
              );
            },
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            AppRouter.createTicketRoute,
          );

          if (result == true && mounted) {
            setState(() {});
          }
        },
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Buat Tiket'),
      ),
    );
  }
}