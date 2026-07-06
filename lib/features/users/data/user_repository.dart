import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final userRepositoryProvider =
    Provider<UserRepository>((ref) {
  return UserRepository();
});

class UserRepository {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await _supabase
        .from('profiles')
        .select(
          'id, full_name, name, email, role, is_active',
        )
        .order(
          'full_name',
          ascending: true,
        );

    return List<Map<String, dynamic>>.from(
      response,
    );
  }

  Future<Map<String, dynamic>> getUserById(
    String userId,
  ) async {
    final response = await _supabase
        .from('profiles')
        .select(
          'id, full_name, name, email, role, is_active',
        )
        .eq('id', userId)
        .single();

    return Map<String, dynamic>.from(
      response,
    );
  }

  Future<void> createUserByAdmin({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    final normalizedFullName =
        fullName.trim();

    final normalizedEmail =
        email.trim().toLowerCase();

    final normalizedRole =
        role.trim().toLowerCase();

    if (normalizedFullName.isEmpty) {
      throw Exception(
        'Nama lengkap wajib diisi',
      );
    }

    if (normalizedEmail.isEmpty ||
        !normalizedEmail.contains('@')) {
      throw Exception(
        'Format email tidak valid',
      );
    }

    if (password.length < 6) {
      throw Exception(
        'Password minimal 6 karakter',
      );
    }

    if (normalizedRole != 'admin' &&
        normalizedRole != 'helpdesk') {
      throw Exception(
        'Role hanya boleh Admin atau Helpdesk',
      );
    }

    final session =
        _supabase.auth.currentSession;

    if (session == null) {
      throw Exception(
        'Sesi login Admin tidak ditemukan',
      );
    }

    final response =
        await _supabase.functions.invoke(
      'create-user',
      body: {
        'full_name': normalizedFullName,
        'email': normalizedEmail,
        'password': password,
        'role': normalizedRole,
      },
    );

    final responseData = response.data;

    if (responseData is Map) {
      final success =
          responseData['success'] == true;

      if (!success) {
        throw Exception(
          responseData['message']?.toString() ??
              'Gagal membuat akun',
        );
      }

      return;
    }

    if (response.status < 200 ||
        response.status >= 300) {
      throw Exception(
        'Edge Function gagal dijalankan',
      );
    }
  }

  Future<void> toggleUserStatus(
    String userId,
    bool isActive,
  ) async {
    final currentUserId =
        _supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      throw Exception(
        'Pengguna belum login',
      );
    }

    if (currentUserId == userId) {
      throw Exception(
        'Admin tidak dapat menonaktifkan akunnya sendiri',
      );
    }

    final updatedUsers = await _supabase
        .from('profiles')
        .update({
          'is_active': isActive,
        })
        .eq('id', userId)
        .select();

    if (updatedUsers.isEmpty) {
      throw Exception(
        'Pengguna gagal diperbarui',
      );
    }
  }

  Future<void> updateUserRole(
    String userId,
    String role,
  ) async {
    final normalizedRole =
        role.trim().toLowerCase();

    const allowedRoles = {
      'user',
      'helpdesk',
      'admin',
    };

    if (!allowedRoles.contains(
      normalizedRole,
    )) {
      throw Exception(
        'Role pengguna tidak valid',
      );
    }

    final updatedUsers = await _supabase
        .from('profiles')
        .update({
          'role': normalizedRole,
        })
        .eq('id', userId)
        .select();

    if (updatedUsers.isEmpty) {
      throw Exception(
        'Role pengguna gagal diperbarui',
      );
    }
  }
}