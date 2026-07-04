import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final commentRepositoryProvider = Provider((ref) => CommentRepository());

class CommentRepository {
  final _supabase = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> getCommentsStream(String ticketId) {
    return _supabase
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);
  }

  Future<void> addComment(String ticketId, String userId, String message) async {
    await _supabase.from('comments').insert({
      'ticket_id': ticketId,
      'user_id': userId,
      'content': message, // <-- Udah diganti jadi 'content' sesuai skema database lu
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}