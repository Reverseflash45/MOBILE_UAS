import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/Provider/settings_provider.dart';

class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNotifEnabled = ref.watch(settingsProvider);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: const Icon(Icons.person, color: Colors.indigo),
              title: const Text('Profil Saya'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, AppRouter.profileRoute),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              secondary: const Icon(Icons.notifications_active, color: Colors.indigo),
              title: const Text('Notifikasi Push'),
              subtitle: const Text('Tampilkan pop-up saat ada tiket baru'),
              value: isNotifEnabled,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).toggleNotifications(value);
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              secondary: const Icon(Icons.dark_mode, color: Colors.indigo),
              title: const Text('Mode Gelap'),
              value: themeMode == ThemeMode.dark,
              onChanged: (value) {
                ref.read(themeProvider.notifier).toggleTheme();
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: const Icon(Icons.notifications, color: Colors.indigo),
              title: const Text('Riwayat Notifikasi'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, AppRouter.notificationRoute),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: const Icon(Icons.info, color: Colors.indigo),
              title: const Text('Tentang Aplikasi'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.loginRoute,
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Keluar dari Akun'),
          ),
        ],
      ),
    );
  }
}