import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final userRepositoryProvider = Provider((ref) => UserRepository());

class UserRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await _supabase.from('profiles').select().order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> toggleUserStatus(String userId, bool isActive) async {
    await _supabase.from('profiles').update({'is_active': isActive}).eq('id', userId);
  }
}