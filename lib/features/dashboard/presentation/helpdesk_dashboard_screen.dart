import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../auth/data/auth_repository.dart';

class HelpdeskDashboardScreen extends ConsumerWidget {
  const HelpdeskDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Helpdesk'),
        actions: [
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
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: const Icon(Icons.assignment, size: 40, color: Colors.indigo),
              title: const Text('Tugas Saya', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Lihat tiket yang ditugaskan kepada Anda'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, AppRouter.listTicketRoute),
            ),
          ),
        ],
      ),
    );
  }
}