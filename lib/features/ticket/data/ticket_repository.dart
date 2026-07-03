import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository(SupabaseClientConfig.client);
});

class TicketRepository {
  final SupabaseClient _client;

  TicketRepository(this._client);

  Stream<List<Map<String, dynamic>>> getTicketsStream() {
    return _client
        .from('tickets')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  Future<void> createTicket({
    required String title,
    required String description,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('tickets').insert({
      'title': title,
      'description': description,
      'status': 'open',
      'user_id': userId,
    });
  }

  Future<void> acceptTicket(String ticketId) async {
    await _client.from('tickets').update({
      'status': 'assign'
    }).eq('id', ticketId);
  }

  Future<void> assignTicket(String ticketId, String helpdeskId) async {
    await _client.from('tickets').update({
      'status': 'in progress',
      'helpdesk_id': helpdeskId,
    }).eq('id', ticketId);
  }

  Future<void> closeTicket(String ticketId) async {
    await _client.from('tickets').update({
      'status': 'close'
    }).eq('id', ticketId);
  }

  Future<List<Map<String, dynamic>>> getHelpdeskUsers() async {
    final response = await _client
        .from('profiles')
        .select('id, full_name')
        .eq('role', 'helpdesk');
    return List<Map<String, dynamic>>.from(response);
  }
}