import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../auth/data/auth_repository.dart';
import '../data/ticket_repository.dart';

class DetailTicketScreen extends ConsumerStatefulWidget {
  const DetailTicketScreen({super.key});

  @override
  ConsumerState<DetailTicketScreen> createState() =>
      _DetailTicketScreenState();
}

class _DetailTicketScreenState
    extends ConsumerState<DetailTicketScreen> {
  String? _userRole;
  String? _currentUserId;
  String? _ticketId;

  Map<String, dynamic>? _ticket;
  List<Map<String, dynamic>> _helpdeskUsers = [];

  String? _selectedHelpdeskId;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_ticketId != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic> && args['id'] != null) {
      _ticketId = args['id'].toString();
      _ticket = Map<String, dynamic>.from(args);
      _fetchInitialData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchInitialData() async {
    final authRepo = ref.read(authRepositoryProvider);
    final user = authRepo.currentUser;

    if (user == null || _ticketId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      _currentUserId = user.id;
      final role = await authRepo.getUserRole(user.id);

      final ticketResponse = await Supabase.instance.client
          .from('tickets')
          .select()
          .eq('id', _ticketId!)
          .single();

      List<Map<String, dynamic>> helpdeskUsers = [];

      if (role == 'admin') {
        helpdeskUsers = await ref
            .read(ticketRepositoryProvider)
            .getHelpdeskUsers();
      }

      if (!mounted) return;

      setState(() {
        _userRole = role?.toLowerCase();
        _ticket = Map<String, dynamic>.from(ticketResponse);
        _helpdeskUsers = helpdeskUsers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat detail tiket: $e')),
      );
    }
  }

  Future<void> _refreshTicket() async {
    if (_ticketId == null) return;

    final response = await Supabase.instance.client
        .from('tickets')
        .select()
        .eq('id', _ticketId!)
        .single();

    if (!mounted) return;

    setState(() {
      _ticket = Map<String, dynamic>.from(response);
    });
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await action();
      await _refreshTicket();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Proses gagal: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
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

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'OPEN';
      case 'assign':
        return 'DITERIMA ADMIN';
      case 'in progress':
        return 'DIPROSES HELPDESK';
      case 'close':
        return 'SELESAI';
      default:
        return status.toUpperCase();
    }
  }

  bool get _isAssignedToCurrentHelpdesk {
    final assignedTo = _ticket?['assigned_to']?.toString();

    return _userRole == 'helpdesk' &&
        assignedTo != null &&
        assignedTo == _currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_ticket == null || _ticketId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Tiket')),
        body: const Center(child: Text('Data tiket tidak ditemukan')),
      );
    }

    final title = _ticket!['title']?.toString() ?? '-';
    final description =
        _ticket!['description']?.toString() ?? '-';
    final status =
        _ticket!['status']?.toString().toLowerCase() ?? 'open';
    final attachmentUrl =
        _ticket!['attachment_url']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _userRole == 'helpdesk'
              ? 'Penanganan Tiket'
              : 'Detail Tiket',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline),
            tooltip: 'Tracking tiket',
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRouter.trackingTicketRoute,
                arguments: _ticket,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTicket,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status Saat Ini:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Chip(
                          label: Text(
                            _getStatusLabel(status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor:
                              _getStatusColor(status),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    if (attachmentUrl != null &&
                        attachmentUrl.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Lampiran:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          attachmentUrl,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const Text(
                              'Lampiran tidak dapat ditampilkan',
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_userRole == 'admin' && status == 'open')
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Terima Tiket'),
                onPressed: _isProcessing
                    ? null
                    : () => _runAction(
                          () => ref
                              .read(ticketRepositoryProvider)
                              .acceptTicket(_ticketId!),
                          'Tiket diterima oleh admin',
                        ),
              ),

            if (_userRole == 'admin' && status == 'assign') ...[
              DropdownButtonFormField<String>(
                value: _selectedHelpdeskId,
                decoration: const InputDecoration(
                  labelText: 'Pilih Helpdesk',
                  prefixIcon: Icon(Icons.support_agent),
                ),
                items: _helpdeskUsers.map((user) {
                  return DropdownMenuItem<String>(
                    value: user['id'].toString(),
                    child: Text(
                      user['full_name']?.toString() ??
                          'Helpdesk',
                    ),
                  );
                }).toList(),
                onChanged: _isProcessing
                    ? null
                    : (value) {
                        setState(() {
                          _selectedHelpdeskId = value;
                        });
                      },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.assignment_ind),
                label: const Text('Tugaskan ke Helpdesk'),
                onPressed: _isProcessing ||
                        _selectedHelpdeskId == null
                    ? null
                    : () => _runAction(
                          () => ref
                              .read(ticketRepositoryProvider)
                              .assignTicket(
                                _ticketId!,
                                _selectedHelpdeskId!,
                              ),
                          'Tiket berhasil diteruskan ke helpdesk',
                        ),
              ),
            ],

            if (_userRole == 'helpdesk' &&
                status == 'in progress' &&
                _isAssignedToCurrentHelpdesk)
              ElevatedButton.icon(
                icon: const Icon(Icons.task_alt),
                label: const Text('Selesaikan Tiket'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isProcessing
                    ? null
                    : () => _runAction(
                          () => ref
                              .read(ticketRepositoryProvider)
                              .closeTicket(_ticketId!),
                          'Tiket berhasil diselesaikan',
                        ),
              ),

            if (_userRole == 'helpdesk' &&
                !_isAssignedToCurrentHelpdesk)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Tiket ini tidak ditugaskan kepada akun helpdesk ini.',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ),

            if (status == 'close')
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Tiket telah selesai',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
