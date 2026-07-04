import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/app_router.dart';
import '../../auth/data/auth_repository.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: const Icon(Icons.book_online, size: 40, color: Colors.indigo),
              title: const Text('Semua Tiket', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Pantau dan delegasikan tiket masuk'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, AppRouter.listTicketRoute),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: const Icon(Icons.manage_accounts, size: 40, color: Colors.indigo),
              title: const Text('Kelola Pengguna', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Tambah atau hapus akun helpdesk'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, AppRouter.userListRoute),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: const Icon(Icons.person, size: 40, color: Colors.indigo),
              title: const Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Lihat informasi akun admin'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, AppRouter.profileRoute),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: const Icon(Icons.settings, size: 40, color: Colors.indigo),
              title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Ubah tema dan logout aplikasi'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, AppRouter.settingRoute),
            ),
          ),
        ],
      ),
    );
  }
}