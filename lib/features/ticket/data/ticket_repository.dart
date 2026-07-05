import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository(SupabaseClientConfig.client);
});

class TicketRepository {
  final SupabaseClient _client;

  TicketRepository(this._client);

  String get _currentUserId {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('Pengguna belum login');
    }

    return userId;
  }

  Future<String> _getCurrentUserRole() async {
    final response = await _client
        .from('profiles')
        .select('role')
        .eq('id', _currentUserId)
        .single();

    return response['role']?.toString().toLowerCase() ?? '';
  }

  Future<void> _logHistory({
    required String ticketId,
    required String status,
    required String action,
    required String description,
  }) async {
    await _client.from('ticket_histories').insert({
      'ticket_id': ticketId,
      'status': status,
      'action': action,
      'description': description,
      'changed_by': _currentUserId,
    });
  }

  Future<List<Map<String, dynamic>>> getTicketsPaginated(
    int limit,
    int offset,
  ) async {
    final role = await _getCurrentUserRole();
    final userId = _currentUserId;

    dynamic query = _client.from('tickets').select();

    if (role == 'user') {
      query = query.eq('user_id', userId);
    } else if (role == 'helpdesk') {
      query = query.eq('assigned_to', userId);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> getTicketById(
    String ticketId,
  ) async {
    final response = await _client
        .from('tickets')
        .select()
        .eq('id', ticketId)
        .single();

    return Map<String, dynamic>.from(response);
  }

  Future<void> createTicket({
    required String title,
    required String description,
    String? attachmentUrl,
  }) async {
    final response = await _client
        .from('tickets')
        .insert({
          'title': title,
          'description': description,
          'attachment_url': attachmentUrl,
          'status': 'open',
          'user_id': _currentUserId,
          'assigned_to': null,
        })
        .select()
        .single();

    final ticketId = response['id'].toString();

    await _logHistory(
      ticketId: ticketId,
      status: 'open',
      action: 'CREATED',
      description: 'Tiket baru dibuat oleh pengguna',
    );
  }

  Future<void> acceptTicket(String ticketId) async {
    final role = await _getCurrentUserRole();

    if (role != 'admin') {
      throw Exception('Hanya admin yang dapat menerima tiket');
    }

    final updatedTickets = await _client
        .from('tickets')
        .update({
          'status': 'assign',
        })
        .eq('id', ticketId)
        .eq('status', 'open')
        .select();

    if (updatedTickets.isEmpty) {
      throw Exception(
        'Tiket tidak ditemukan atau statusnya bukan open',
      );
    }

    await _logHistory(
      ticketId: ticketId,
      status: 'assign',
      action: 'ACCEPTED',
      description: 'Tiket diterima oleh admin',
    );
  }

  Future<void> assignTicket(
    String ticketId,
    String helpdeskId,
  ) async {
    final role = await _getCurrentUserRole();

    if (role != 'admin') {
      throw Exception(
        'Hanya admin yang dapat menugaskan tiket',
      );
    }

    final helpdeskProfile = await _client
        .from('profiles')
        .select('id, full_name, role')
        .eq('id', helpdeskId)
        .eq('role', 'helpdesk')
        .maybeSingle();

    if (helpdeskProfile == null) {
      throw Exception('Akun helpdesk tidak ditemukan');
    }

    final updatedTickets = await _client
        .from('tickets')
        .update({
          'status': 'in progress',
          'assigned_to': helpdeskId,
        })
        .eq('id', ticketId)
        .eq('status', 'assign')
        .select();

    if (updatedTickets.isEmpty) {
      throw Exception(
        'Tiket tidak ditemukan atau belum diterima admin',
      );
    }

    final helpdeskName =
        helpdeskProfile['full_name']?.toString() ?? 'Helpdesk';

    await _logHistory(
      ticketId: ticketId,
      status: 'in progress',
      action: 'ASSIGNED',
      description: 'Tiket ditugaskan kepada $helpdeskName',
    );
  }

  Future<void> closeTicket(String ticketId) async {
    final role = await _getCurrentUserRole();

    if (role != 'helpdesk') {
      throw Exception(
        'Hanya helpdesk yang dapat menyelesaikan tiket',
      );
    }

    final updatedTickets = await _client
        .from('tickets')
        .update({
          'status': 'close',
        })
        .eq('id', ticketId)
        .eq('assigned_to', _currentUserId)
        .eq('status', 'in progress')
        .select();

    if (updatedTickets.isEmpty) {
      throw Exception(
        'Tiket bukan tugas akun helpdesk ini atau sudah selesai',
      );
    }

    await _logHistory(
      ticketId: ticketId,
      status: 'close',
      action: 'CLOSED',
      description: 'Tiket telah diselesaikan oleh helpdesk',
    );
  }

  Future<void> deleteTicket(String ticketId) async {
    final role = await _getCurrentUserRole();

    if (role != 'admin') {
      throw Exception('Hanya admin yang dapat menghapus tiket');
    }

    await _client
        .from('tickets')
        .delete()
        .eq('id', ticketId);
  }

  Future<List<Map<String, dynamic>>> getHelpdeskUsers() async {
    final response = await _client
        .from('profiles')
        .select('id, full_name, role')
        .eq('role', 'helpdesk')
        .order('full_name', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getTicketHistories(
    String ticketId,
  ) async {
    final response = await _client
        .from('ticket_histories')
        .select()
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }
}