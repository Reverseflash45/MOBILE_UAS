import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository(SupabaseClientConfig.client);
});

class TicketRepository {
  final SupabaseClient _client;

  TicketRepository(this._client);

  Future<void> _logHistory(String ticketId, String action, String description) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    
    await _client.from('ticket_histories').insert({
      'ticket_id': ticketId,
      'user_id': userId,
      'action': action,
      'description': description,
    });
  }

  Future<List<Map<String, dynamic>>> getTicketsPaginated(int limit, int offset) async {
    final response = await _client
        .from('tickets')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createTicket({
    required String title,
    required String description,
    String? attachmentUrl,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client.from('tickets').insert({
      'title': title,
      'description': description,
      'attachment_url': attachmentUrl,
      'status': 'open',
      'user_id': userId,
    }).select().single();

    await _logHistory(response['id'], 'CREATED', 'Tiket baru dibuat');
  }

  Future<void> acceptTicket(String ticketId) async {
    await _client.from('tickets').update({
      'status': 'assign'
    }).eq('id', ticketId);
    
    await _logHistory(ticketId, 'ASSIGNED', 'Tiket diterima dan sedang diproses');
  }

  Future<void> assignTicket(String ticketId, String helpdeskId) async {
    await _client.from('tickets').update({
      'status': 'in progress',
      'helpdesk_id': helpdeskId,
    }).eq('id', ticketId);

    await _logHistory(ticketId, 'IN PROGRESS', 'Tiket ditugaskan ke Helpdesk');
  }

  Future<void> closeTicket(String ticketId) async {
    await _client.from('tickets').update({
      'status': 'close'
    }).eq('id', ticketId);

    await _logHistory(ticketId, 'CLOSED', 'Tiket telah diselesaikan dan ditutup');
  }

  Future<void> deleteTicket(String ticketId) async {
    await _client.from('tickets').delete().eq('id', ticketId);
  }

  Future<List<Map<String, dynamic>>> getHelpdeskUsers() async {
    final response = await _client
        .from('profiles')
        .select('id, full_name')
        .eq('role', 'helpdesk');
    return List<Map<String, dynamic>>.from(response);
  }
}