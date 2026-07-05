import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../../../core/services/notification_service.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository(SupabaseClientConfig.client);
});

class TicketRepository {
  final SupabaseClient _client;
  final NotificationService _notificationService =
      NotificationService();

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

    return response['role']
            ?.toString()
            .trim()
            .toLowerCase() ??
        '';
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

  Future<List<String>> _getAdminIds() async {
    final response = await _client
        .from('profiles')
        .select('id, role');

    final profiles =
        List<Map<String, dynamic>>.from(response);

    final adminIds = <String>[];

    for (final profile in profiles) {
      final role = profile['role']
              ?.toString()
              .trim()
              .toLowerCase() ??
          '';

      final id = profile['id']?.toString();

      if (role == 'admin' &&
          id != null &&
          id.isNotEmpty) {
        adminIds.add(id);
      }
    }

    if (adminIds.isEmpty) {
      throw Exception(
        'Tidak ada akun admin yang ditemukan di tabel profiles',
      );
    }

    return adminIds;
  }

  Future<void> _notifyAdmins({
    required String ticketId,
    required String title,
    required String message,
    required String type,
  }) async {
    final adminIds = await _getAdminIds();

    for (final adminId in adminIds) {
      await _notificationService.createNotification(
        userId: adminId,
        ticketId: ticketId,
        title: title,
        message: message,
        type: type,
      );
    }
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

    await _notificationService.createNotification(
      userId: _currentUserId,
      ticketId: ticketId,
      title: 'Tiket Berhasil Dibuat',
      message:
          'Tiket "$title" berhasil dibuat dan sedang menunggu admin.',
      type: 'ticket_created',
    );

    await _notifyAdmins(
      ticketId: ticketId,
      title: 'Tiket Baru Masuk',
      message:
          'Pengguna membuat tiket baru berjudul "$title".',
      type: 'ticket_new',
    );
  }

  Future<void> acceptTicket(String ticketId) async {
    final role = await _getCurrentUserRole();

    if (role != 'admin') {
      throw Exception(
        'Hanya admin yang dapat menerima tiket',
      );
    }

    final ticket = await _client
        .from('tickets')
        .select('user_id, title, status')
        .eq('id', ticketId)
        .single();

    final currentStatus =
        ticket['status']?.toString().trim().toLowerCase();

    if (currentStatus != 'open') {
      throw Exception(
        'Tiket sudah diproses atau statusnya bukan open',
      );
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
        'Tiket tidak ditemukan atau gagal diterima',
      );
    }

    await _logHistory(
      ticketId: ticketId,
      status: 'assign',
      action: 'ACCEPTED',
      description: 'Tiket diterima oleh admin',
    );

    await _notificationService.createNotification(
      userId: ticket['user_id'].toString(),
      ticketId: ticketId,
      title: 'Tiket Diterima Admin',
      message:
          'Tiket "${ticket['title']}" telah diterima oleh admin.',
      type: 'ticket_accepted',
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

    final ticket = await _client
        .from('tickets')
        .select('user_id, title, status')
        .eq('id', ticketId)
        .single();

    final currentStatus =
        ticket['status']?.toString().trim().toLowerCase();

    if (currentStatus != 'assign') {
      throw Exception(
        'Tiket belum diterima admin atau sudah ditugaskan',
      );
    }

    final helpdeskProfile = await _client
        .from('profiles')
        .select('id, full_name, role')
        .eq('id', helpdeskId)
        .maybeSingle();

    if (helpdeskProfile == null) {
      throw Exception(
        'Akun helpdesk tidak ditemukan',
      );
    }

    final helpdeskRole = helpdeskProfile['role']
            ?.toString()
            .trim()
            .toLowerCase() ??
        '';

    if (helpdeskRole != 'helpdesk') {
      throw Exception(
        'Akun yang dipilih bukan akun helpdesk',
      );
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
        'Tiket gagal ditugaskan ke helpdesk',
      );
    }

    final helpdeskName =
        helpdeskProfile['full_name']?.toString() ??
            'Helpdesk';

    await _logHistory(
      ticketId: ticketId,
      status: 'in progress',
      action: 'ASSIGNED',
      description:
          'Tiket ditugaskan kepada $helpdeskName',
    );

    await _notificationService.createNotification(
      userId: helpdeskId,
      ticketId: ticketId,
      title: 'Tiket Baru Ditugaskan',
      message:
          'Anda mendapat tiket "${ticket['title']}" untuk ditangani.',
      type: 'ticket_assigned',
    );

    await _notificationService.createNotification(
      userId: ticket['user_id'].toString(),
      ticketId: ticketId,
      title: 'Tiket Sedang Diproses',
      message:
          'Tiket "${ticket['title']}" telah diteruskan ke helpdesk.',
      type: 'ticket_progress',
    );
  }

  Future<void> closeTicket(String ticketId) async {
    final role = await _getCurrentUserRole();

    if (role != 'helpdesk') {
      throw Exception(
        'Hanya helpdesk yang dapat menyelesaikan tiket',
      );
    }

    final ticket = await _client
        .from('tickets')
        .select(
          'user_id, title, status, assigned_to',
        )
        .eq('id', ticketId)
        .single();

    final assignedTo =
        ticket['assigned_to']?.toString();

    final currentStatus =
        ticket['status']?.toString().trim().toLowerCase();

    if (assignedTo != _currentUserId) {
      throw Exception(
        'Tiket ini bukan tugas akun helpdesk Anda',
      );
    }

    if (currentStatus != 'in progress') {
      throw Exception(
        'Tiket sudah selesai atau belum ditugaskan',
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
        'Tiket gagal diselesaikan',
      );
    }

    await _logHistory(
      ticketId: ticketId,
      status: 'close',
      action: 'CLOSED',
      description:
          'Tiket telah diselesaikan oleh helpdesk',
    );

    await _notificationService.createNotification(
      userId: ticket['user_id'].toString(),
      ticketId: ticketId,
      title: 'Tiket Selesai',
      message:
          'Tiket "${ticket['title']}" telah diselesaikan oleh helpdesk.',
      type: 'ticket_closed',
    );

    await _notifyAdmins(
      ticketId: ticketId,
      title: 'Tiket Diselesaikan',
      message:
          'Helpdesk telah menyelesaikan tiket "${ticket['title']}".',
      type: 'ticket_closed_admin',
    );
  }

  Future<void> deleteTicket(String ticketId) async {
    final role = await _getCurrentUserRole();

    if (role != 'admin') {
      throw Exception(
        'Hanya admin yang dapat menghapus tiket',
      );
    }

    await _client
        .from('tickets')
        .delete()
        .eq('id', ticketId);
  }

  Future<List<Map<String, dynamic>>>
      getHelpdeskUsers() async {
    final response = await _client
        .from('profiles')
        .select('id, full_name, role')
        .order('full_name', ascending: true);

    final profiles =
        List<Map<String, dynamic>>.from(response);

    return profiles.where((profile) {
      final role = profile['role']
              ?.toString()
              .trim()
              .toLowerCase() ??
          '';

      return role == 'helpdesk';
    }).toList();
  }

  Future<List<Map<String, dynamic>>>
      getTicketHistories(
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