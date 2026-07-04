import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../auth/data/auth_repository.dart';
import 'widgets/dashboard_statistic_widget.dart';

class UserDashboardScreen extends ConsumerWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Pengguna'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, AppRouter.profileRoute),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppRouter.settingRoute),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, AppRouter.loginRoute);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const DashboardStatisticWidget(),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: const Icon(Icons.history, size: 40, color: Colors.indigo),
              title: const Text('Riwayat Tiket', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Pantau status laporan Anda'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, AppRouter.listTicketRoute),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRouter.createTicketRoute),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Buat Tiket'),
      ),
    );
  }
}