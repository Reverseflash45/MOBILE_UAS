import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ticket_tracking_page.dart';
import '../widgets/comment_section.dart';
import '../widgets/assign_ticket_dialog.dart';

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
  String userRole = '';
  String? currentUserId;
  late String ticketStatus;
  bool isLoading = true;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();

    ticketStatus =
        widget.ticket['status']?.toString().toLowerCase() ?? 'open';

    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    currentUserId =
        Supabase.instance.client.auth.currentUser?.id;

    if (currentUserId == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', currentUserId!)
          .single();

      if (!mounted) return;

      setState(() {
        userRole =
            response['role']?.toString().toLowerCase() ?? '';
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        userRole = '';
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengambil role pengguna: $e',
          ),
        ),
      );
    }
  }

  Future<void> _deleteTicket() async {
    setState(() {
      isProcessing = true;
    });

    try {
      await Supabase.instance.client
          .from('tickets')
          .delete()
          .eq('id', widget.ticket['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiket berhasil dihapus'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus tiket: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> _completeTicket() async {
    if (currentUserId == null) return;

    setState(() {
      isProcessing = true;
    });

    try {
      await Supabase.instance.client
          .from('tickets')
          .update({
            'status': 'resolved',
          })
          .eq('id', widget.ticket['id'])
          .eq('assigned_to', currentUserId!);

      await Supabase.instance.client
          .from('ticket_histories')
          .insert({
            'ticket_id': widget.ticket['id'],
            'status': 'resolved',
            'action': 'Tiket diselesaikan oleh helpdesk',
            'description':
                'Tiket telah selesai ditangani oleh petugas helpdesk.',
            'changed_by': currentUserId,
          });

      if (!mounted) return;

      setState(() {
        ticketStatus = 'resolved';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tiket berhasil diselesaikan',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyelesaikan tiket: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Tiket'),
          content: const Text(
            'Apakah kamu yakin ingin menghapus tiket ini?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteTicket();
    }
  }

  Future<void> _showCompleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Selesaikan Tiket'),
          content: const Text(
            'Pastikan masalah pengguna sudah selesai ditangani.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Selesaikan'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _completeTicket();
    }
  }

  Color _getStatusColor() {
    switch (ticketStatus) {
      case 'assigned':
        return Colors.orange;
      case 'in_progress':
        return Colors.purple;
      case 'resolved':
      case 'closed':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText() {
    switch (ticketStatus) {
      case 'assigned':
        return 'DITERUSKAN';
      case 'in_progress':
        return 'DIPROSES';
      case 'resolved':
        return 'SELESAI';
      case 'closed':
        return 'DITUTUP';
      default:
        return ticketStatus.toUpperCase();
    }
  }

  bool get isAssignedToCurrentHelpdesk {
    final assignedTo =
        widget.ticket['assigned_to']?.toString();

    return userRole == 'helpdesk' &&
        assignedTo == currentUserId;
  }

  bool get canCompleteTicket {
    return isAssignedToCurrentHelpdesk &&
        ticketStatus != 'resolved' &&
        ticketStatus != 'closed';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final statusColor = _getStatusColor();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          userRole == 'helpdesk'
              ? 'Detail Penanganan Tiket'
              : 'Detail Tiket',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat tiket',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TicketTrackingPage(
                    ticketId:
                        widget.ticket['id'].toString(),
                  ),
                ),
              );
            },
          ),
          if (userRole == 'admin')
            IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              tooltip: 'Hapus tiket',
              onPressed: isProcessing
                  ? null
                  : _showDeleteConfirmation,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.ticket['title'] ??
                          'Tanpa Judul',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            statusColor.withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.ticket['description'] ??
                          'Tidak ada deskripsi',
                      style:
                          const TextStyle(fontSize: 16),
                    ),

                    // Tombol khusus admin
                    if (userRole == 'admin' &&
                        ticketStatus != 'resolved' &&
                        ticketStatus != 'closed') ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.assignment_ind,
                          ),
                          label: const Text(
                            'Teruskan ke Helpdesk',
                          ),
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.indigo,
                            foregroundColor:
                                Colors.white,
                          ),
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  final result =
                                      await showDialog<
                                          bool>(
                                    context: context,
                                    builder: (context) =>
                                        AssignTicketDialog(
                                      ticketId: widget
                                          .ticket['id']
                                          .toString(),
                                    ),
                                  );

                                  if (result == true &&
                                      mounted) {
                                    Navigator.pop(
                                      context,
                                      true,
                                    );
                                  }
                                },
                        ),
                      ),
                    ],

                    // Tombol khusus helpdesk
                    if (canCompleteTicket) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon:
                              const Icon(Icons.check),
                          label: Text(
                            isProcessing
                                ? 'Memproses...'
                                : 'Selesaikan Tiket',
                          ),
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.green,
                            foregroundColor:
                                Colors.white,
                          ),
                          onPressed: isProcessing
                              ? null
                              : _showCompleteConfirmation,
                        ),
                      ),
                    ],

                    if (userRole == 'helpdesk' &&
                        !isAssignedToCurrentHelpdesk)
                      const Padding(
                        padding:
                            EdgeInsets.only(top: 16),
                        child: Text(
                          'Tiket ini tidak ditugaskan kepada akun helpdesk ini.',
                          style: TextStyle(
                            color: Colors.orange,
                          ),
                        ),
                      ),

                    if (ticketStatus == 'resolved' ||
                        ticketStatus == 'closed')
                      const Padding(
                        padding:
                            EdgeInsets.only(top: 16),
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
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: CommentSection(
              ticketId:
                  widget.ticket['id'].toString(),
            ),
          ),
        ],
      ),
    );
  }
}