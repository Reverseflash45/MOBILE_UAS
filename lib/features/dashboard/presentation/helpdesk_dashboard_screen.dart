import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/notification_service.dart';
import '../../dashboard/presentation/widgets/dashboard_statistic_widget.dart';

class HelpdeskDashboardScreen extends ConsumerStatefulWidget {
  const HelpdeskDashboardScreen({super.key});

  @override
  ConsumerState<HelpdeskDashboardScreen> createState() => _HelpdeskDashboardScreenState();
}

class _HelpdeskDashboardScreenState extends ConsumerState<HelpdeskDashboardScreen> {
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId != null) {
      NotificationService().initializeNotificationListener(
        currentUserId: currentUserId!,
        onNewNotification: (payload) {},
      );
    }
  }

  Widget _buildMenuCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 28, color: Colors.indigo),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Helpdesk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, AppRouter.profileRoute),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.pushNamed(context, AppRouter.notificationRoute),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRouter.settingRoute),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          DashboardStatisticWidget(helpdeskId: currentUserId),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(bottom: 12.0, left: 4.0),
            child: Text('Menu Utama', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          _buildMenuCard(
            icon: Icons.assignment,
            title: 'Tugas Saya',
            subtitle: 'Lihat tiket yang ditugaskan kepada Anda',
            onTap: () => Navigator.pushNamed(context, AppRouter.listTicketRoute),
          ),
        ],
      ),
    );
  }
}