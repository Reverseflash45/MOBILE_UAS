import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../ticket/data/ticket_repository.dart';
import '../widgets/assign_ticket_dialog.dart';
import '../widgets/comment_section.dart';
import 'ticket_tracking_page.dart';

class TicketDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> ticket;

  const TicketDetailPage({
    super.key,
    required this.ticket,
  });

  @override
  ConsumerState<TicketDetailPage> createState() =>
      _TicketDetailPageState();
}

class _TicketDetailPageState
    extends ConsumerState<TicketDetailPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  late Map<String, dynamic> _ticket;

  String _userRole = '';
  String? _currentUserId;

  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    _ticket = Map<String, dynamic>.from(widget.ticket);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      return;
    }

    try {
      _currentUserId = currentUser.id;

      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', currentUser.id)
          .single();

      final freshTicket = await ref
          .read(ticketRepositoryProvider)
          .getTicketById(
            _ticket['id'].toString(),
          );

      if (!mounted) return;

      setState(() {
        _userRole = profile['role']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

        _ticket =
            Map<String, dynamic>.from(freshTicket);

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memuat detail tiket: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshTicket() async {
    try {
      final freshTicket = await ref
          .read(ticketRepositoryProvider)
          .getTicketById(
            _ticket['id'].toString(),
          );

      if (!mounted) return;

      setState(() {
        _ticket =
            Map<String, dynamic>.from(freshTicket);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memperbarui tiket: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _runAction({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await action();
      await _refreshTicket();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Proses gagal: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _acceptTicket() async {
    await _runAction(
      action: () => ref
          .read(ticketRepositoryProvider)
          .acceptTicket(
            _ticket['id'].toString(),
          ),
      successMessage:
          'Tiket berhasil diterima admin',
    );
  }

  Future<void> _assignTicket() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AssignTicketDialog(
          ticketId: _ticket['id'].toString(),
        );
      },
    );

    if (result == true) {
      await _refreshTicket();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tiket berhasil ditugaskan ke helpdesk',
          ),
        ),
      );
    }
  }

  Future<void> _startTicket() async {
    final ticketId =
        _ticket['id'].toString();

    await _runAction(
      action: () async {
        await _supabase
            .from('tickets')
            .update({
              'status': 'in progress',
            })
            .eq('id', ticketId);

        await _supabase
            .from('ticket_histories')
            .insert({
              'ticket_id': ticketId,
              'status': 'in progress',
              'description':
                  'Tiket mulai ditangani oleh helpdesk',
              'changed_by': _currentUserId,
              'action':
                  'Mulai penanganan tiket',
            });
      },
      successMessage:
          'Tiket mulai dikerjakan',
    );
  }

  Future<void> _completeTicket() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Selesaikan Tiket',
          ),
          content: const Text(
            'Pastikan masalah pengguna sudah selesai ditangani.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Batal',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Selesaikan',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _runAction(
      action: () => ref
          .read(ticketRepositoryProvider)
          .closeTicket(
            _ticket['id'].toString(),
          ),
      successMessage:
          'Tiket berhasil diselesaikan',
    );
  }

  Future<void> _deleteTicket() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Hapus Tiket',
          ),
          content: const Text(
            'Tiket dan seluruh riwayat terkait akan dihapus. Lanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Batal',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Hapus',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await ref
          .read(ticketRepositoryProvider)
          .deleteTicket(
            _ticket['id'].toString(),
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tiket berhasil dihapus',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus tiket: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String get _status {
    final rawStatus = _ticket['status']
            ?.toString()
            .trim()
            .toLowerCase() ??
        'open';

    if (rawStatus == 'assigned') {
      return 'assign';
    }

    return rawStatus;
  }

  bool get _isAssignedToCurrentHelpdesk {
    final assignedTo =
        _ticket['assigned_to']?.toString();

    return _userRole == 'helpdesk' &&
        assignedTo != null &&
        assignedTo == _currentUserId;
  }

  String _getStatusLabel(
    String status,
  ) {
    switch (status) {
      case 'open':
        return 'MENUNGGU ADMIN';

      case 'assign':
        return 'DITUGASKAN';

      case 'in progress':
        return 'DIPROSES HELPDESK';

      case 'close':
        return 'SELESAI';

      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(
    String status,
  ) {
    switch (status) {
      case 'open':
        return Colors.blue;

      case 'assign':
        return Colors.orange;

      case 'in progress':
        return Colors.purple;

      case 'close':
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  Widget _buildTicketCard() {
    final statusColor =
        _getStatusColor(_status);

    final attachmentUrl =
        _ticket['attachment_url']?.toString();

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    'Status Saat Ini',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor
                        .withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor,
                    ),
                  ),
                  child: Text(
                    _getStatusLabel(
                      _status,
                    ),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(
              height: 32,
            ),
            Text(
              _ticket['title']
                      ?.toString() ??
                  'Tanpa Judul',
              style: const TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 14,
            ),
            Text(
              _ticket['description']
                      ?.toString() ??
                  'Tidak ada deskripsi',
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            if (attachmentUrl != null &&
                attachmentUrl.isNotEmpty) ...[
              const SizedBox(
                height: 20,
              ),
              const Text(
                'Lampiran',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
                child: Image.network(
                  attachmentUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  loadingBuilder: (
                    context,
                    child,
                    loadingProgress,
                  ) {
                    if (loadingProgress ==
                        null) {
                      return child;
                    }

                    return const SizedBox(
                      height: 220,
                      child: Center(
                        child:
                            CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Container(
                      height: 120,
                      width: double.infinity,
                      alignment:
                          Alignment.center,
                      color:
                          Colors.grey.shade200,
                      child: const Text(
                        'Lampiran tidak dapat ditampilkan',
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdminAction() {
    if (_userRole != 'admin') {
      return const SizedBox.shrink();
    }

    if (_status == 'open') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(
            Icons.check_circle_outline,
          ),
          label: Text(
            _isProcessing
                ? 'Memproses...'
                : 'Terima Tiket',
          ),
          onPressed: _isProcessing
              ? null
              : _acceptTicket,
        ),
      );
    }

    if (_status == 'assign' &&
        _ticket['assigned_to'] == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(
            Icons.assignment_ind,
          ),
          label: const Text(
            'Tugaskan ke Helpdesk',
          ),
          onPressed: _isProcessing
              ? null
              : _assignTicket,
        ),
      );
    }

    if (_status == 'assign' &&
        _ticket['assigned_to'] != null) {
      return const Card(
        child: Padding(
          padding:
              EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.assignment_ind,
                color: Colors.orange,
              ),
              SizedBox(
                width: 12,
              ),
              Expanded(
                child: Text(
                  'Tiket sudah ditugaskan kepada helpdesk.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_status == 'in progress') {
      return const Card(
        child: Padding(
          padding:
              EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.support_agent,
                color: Colors.purple,
              ),
              SizedBox(
                width: 12,
              ),
              Expanded(
                child: Text(
                  'Tiket sedang ditangani oleh helpdesk.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_status == 'close') {
      return const Card(
        child: Padding(
          padding:
              EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              SizedBox(
                width: 12,
              ),
              Expanded(
                child: Text(
                  'Tiket telah selesai',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildHelpdeskAction() {
    if (_userRole != 'helpdesk') {
      return const SizedBox.shrink();
    }

    if (!_isAssignedToCurrentHelpdesk) {
      return const Card(
        child: Padding(
          padding:
              EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: Colors.orange,
              ),
              SizedBox(
                width: 12,
              ),
              Expanded(
                child: Text(
                  'Tiket ini tidak ditugaskan kepada akun helpdesk Anda.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_status == 'assign') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(
            Icons.play_arrow,
          ),
          label: Text(
            _isProcessing
                ? 'Memproses...'
                : 'Mulai Kerjakan',
          ),
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                Colors.blue,
            foregroundColor:
                Colors.white,
            padding:
                const EdgeInsets.symmetric(
              vertical: 14,
            ),
          ),
          onPressed: _isProcessing
              ? null
              : _startTicket,
        ),
      );
    }

    if (_status == 'in progress') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(
            Icons.task_alt,
          ),
          label: Text(
            _isProcessing
                ? 'Memproses...'
                : 'Selesaikan Tiket',
          ),
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                Colors.green,
            foregroundColor:
                Colors.white,
            padding:
                const EdgeInsets.symmetric(
              vertical: 14,
            ),
          ),
          onPressed: _isProcessing
              ? null
              : _completeTicket,
        ),
      );
    }

    if (_status == 'close') {
      return const Card(
        child: Padding(
          padding:
              EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              SizedBox(
                width: 12,
              ),
              Expanded(
                child: Text(
                  'Tiket telah selesai ditangani.',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildUserStatus() {
    if (_userRole != 'user') {
      return const SizedBox.shrink();
    }

    late String message;
    late IconData icon;
    late Color color;

    switch (_status) {
      case 'open':
        message =
            'Tiket sedang menunggu pemeriksaan admin.';
        icon =
            Icons.hourglass_empty;
        color = Colors.blue;
        break;

      case 'assign':
        message =
            'Tiket sudah diterima dan ditugaskan kepada helpdesk.';
        icon =
            Icons.assignment_turned_in;
        color = Colors.orange;
        break;

      case 'in progress':
        message =
            'Tiket sedang ditangani oleh helpdesk.';
        icon =
            Icons.support_agent;
        color = Colors.purple;
        break;

      case 'close':
        message =
            'Tiket telah selesai ditangani.';
        icon =
            Icons.check_circle;
        color = Colors.green;
        break;

      default:
        message =
            'Status tiket tidak diketahui.';
        icon =
            Icons.info_outline;
        color = Colors.grey;
    }

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Text(
                message,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _userRole == 'helpdesk'
              ? 'Detail Penanganan Tiket'
              : 'Detail Tiket',
        ),
        actions: [
          IconButton(
            tooltip:
                'Tracking Tiket',
            icon: const Icon(
              Icons.timeline,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (
                    context,
                  ) {
                    return TicketTrackingPage(
                      ticketId:
                          _ticket['id']
                              .toString(),
                    );
                  },
                ),
              );
            },
          ),
          if (_userRole == 'admin')
            IconButton(
              tooltip:
                  'Hapus Tiket',
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              onPressed:
                  _isProcessing
                      ? null
                      : _deleteTicket,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child:
                RefreshIndicator(
              onRefresh:
                  _refreshTicket,
              child: ListView(
                padding:
                    const EdgeInsets
                        .all(16),
                children: [
                  _buildTicketCard(),
                  const SizedBox(
                    height: 16,
                  ),
                  _buildAdminAction(),
                  _buildHelpdeskAction(),
                  _buildUserStatus(),
                  const SizedBox(
                    height: 8,
                  ),
                ],
              ),
            ),
          ),
          const Divider(
            height: 1,
          ),
          const Padding(
            padding:
                EdgeInsets.fromLTRB(
              16,
              12,
              16,
              8,
            ),
            child: Row(
              children: [
                Icon(
                  Icons
                      .chat_bubble_outline,
                  size: 20,
                ),
                SizedBox(
                  width: 8,
                ),
                Text(
                  'Komentar & Diskusi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: CommentSection(
              ticketId:
                  _ticket['id']
                      .toString(),
            ),
          ),
        ],
      ),
    );
  }
}