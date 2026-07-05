import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TicketTrackingPage extends StatefulWidget {
  final String ticketId;

  const TicketTrackingPage({
    super.key,
    required this.ticketId,
  });

  @override
  State<TicketTrackingPage> createState() =>
      _TicketTrackingPageState();
}

class _TicketTrackingPageState
    extends State<TicketTrackingPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _histories = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHistories();
  }

  Future<void> _fetchHistories() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _supabase
          .from('ticket_histories')
          .select(
            'id, ticket_id, status, action, description, changed_by, created_at',
          )
          .eq('ticket_id', widget.ticketId)
          .order('created_at', ascending: true);

      if (!mounted) return;

      setState(() {
        _histories = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Icons.confirmation_number_outlined;

      case 'assign':
        return Icons.assignment_turned_in_outlined;

      case 'in progress':
        return Icons.support_agent;

      case 'close':
        return Icons.check_circle_outline;

      default:
        return Icons.history;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Tiket Dibuat';

      case 'assign':
        return 'Diterima Admin';

      case 'in progress':
        return 'Diproses Helpdesk';

      case 'close':
        return 'Tiket Selesai';

      default:
        return status.toUpperCase();
    }
  }

  Widget _buildHistoryCard(Map<String, dynamic> history) {
    final status =
        history['status']?.toString().toLowerCase() ?? '-';

    final action = history['action']?.toString() ?? '';
    final description =
        history['description']?.toString() ?? '';

    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.12),
              child: Icon(
                _getStatusIcon(status),
                color: statusColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (action.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      action,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(description),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(history['created_at']),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Tiket'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchHistories,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchHistories,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _errorMessage != null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 180),
                      const Icon(
                        Icons.error_outline,
                        size: 56,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Gagal memuat riwayat tiket',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchHistories,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  )
                : _histories.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: const [
                          SizedBox(height: 200),
                          Icon(
                            Icons.history_toggle_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada riwayat tracking',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Riwayat akan muncul setelah tiket dibuat, diterima, ditugaskan, atau diselesaikan.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          top: 16,
                          bottom: 24,
                        ),
                        itemCount: _histories.length,
                        itemBuilder: (context, index) {
                          return _buildHistoryCard(
                            _histories[index],
                          );
                        },
                      ),
      ),
    );
  }
}