import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_client.dart';
import '../../../core/router/app_router.dart';

final userListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseClientConfig.client
      .from('profiles')
      .select(
        'id, full_name, name, email, role, is_active',
      )
      .order('email', ascending: true);

  return List<Map<String, dynamic>>.from(response);
});

class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  Future<void> _openAddUserScreen(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await Navigator.pushNamed(
      context,
      AppRouter.addUserRoute,
    );

    if (result == true) {
      ref.invalidate(userListProvider);
    }
  }

  Future<void> _toggleUserStatus({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    required bool newStatus,
  }) async {
    try {
      final currentUserId =
          SupabaseClientConfig.client.auth.currentUser?.id;

      if (currentUserId == userId) {
        throw Exception(
          'Admin tidak dapat menonaktifkan akun sendiri',
        );
      }

      await SupabaseClientConfig.client
          .from('profiles')
          .update({
            'is_active': newStatus,
          })
          .eq('id', userId);

      ref.invalidate(userListProvider);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'Pengguna berhasil diaktifkan'
                : 'Pengguna berhasil dinonaktifkan',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      String message = error.toString();

      if (message.startsWith('Exception: ')) {
        message = message.substring(11);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildUserCard({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> user,
  }) {
    final userId = user['id']?.toString() ?? '';

    final fullName =
        user['full_name']?.toString().trim() ?? '';

    final name =
        user['name']?.toString().trim() ?? '';

    final email =
        user['email']?.toString().trim() ?? '';

    final role =
        user['role']?.toString().trim().toLowerCase() ??
            'user';

    final isActive = user['is_active'] == null
        ? true
        : user['is_active'] == true;

    final displayText = email.isNotEmpty
        ? email
        : fullName.isNotEmpty
            ? fullName
            : name.isNotEmpty
                ? name
                : 'Tanpa Nama';

    String initial = 'U';

    if (fullName.isNotEmpty) {
      initial = fullName[0].toUpperCase();
    } else if (name.isNotEmpty) {
      initial = name[0].toUpperCase();
    } else if (email.isNotEmpty) {
      initial = email[0].toUpperCase();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    displayText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Role: $role'),
                  if (!isActive) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Status: Nonaktif',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: isActive,
              onChanged: userId.isEmpty
                  ? null
                  : (value) {
                      _toggleUserStatus(
                        context: context,
                        ref: ref,
                        userId: userId,
                        newStatus: value,
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userListAsync = ref.watch(userListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pengguna'),
        actions: [
          IconButton(
            tooltip: 'Muat Ulang',
            onPressed: () {
              ref.invalidate(userListProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  _openAddUserScreen(
                    context,
                    ref,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.person_add,
                ),
                label: const Text(
                  'Tambah Pengguna',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: userListAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada pengguna terdaftar',
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(userListProvider);
                    await ref.read(
                      userListProvider.future,
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      16,
                    ),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(
                        context: context,
                        ref: ref,
                        user: users[index],
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) {
                return Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Terjadi kesalahan:\n$error',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.invalidate(
                              userListProvider,
                            );
                          },
                          icon: const Icon(
                            Icons.refresh,
                          ),
                          label: const Text(
                            'Coba Lagi',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}