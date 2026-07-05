import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrackingTicketScreen extends StatefulWidget {
  const TrackingTicketScreen({super.key});

  @override
  State<TrackingTicketScreen> createState() =>
      _TrackingTicketScreenState();
}

class _TrackingTicketScreenState
    extends State<TrackingTicketScreen> {
  Map<String, dynamic>? _ticket;
  List<Map<String, dynamic>> _histories = [];

  bool _isLoading = true;
  String? _error;
  String? _ticketId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_ticketId != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic> && args['id'] != null) {
      _ticketId = args['id'].toString();
      _loadTracking();
    } else {
      setState(() {
        _isLoading = false;
        _error = 'Data tiket tidak ditemukan';
      });
    }
  }

  Future<void> _loadTracking() async {
    if (_ticketId == null) return;

    try {
      final ticketResponse = await Supabase.instance.client
          .from('tickets')
          .select()
          .eq('id', _ticketId!)
          .single();

      final historyResponse = await Supabase.instance.client
          .from('ticket_histories')
          .select()
          .eq('ticket_id', _ticketId!)
          .order('created_at', ascending: true);

      if (!mounted) return;

      setState(() {
        _ticket = Map<String, dynamic>.from(ticketResponse);
        _histories = List<Map<String, dynamic>>.from(
          historyResponse,
        );
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  int _getStatusStep(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 0;
      case 'assign':
        return 1;
      case 'in progress':
        return 2;
      case 'close':
        return 3;
      default:
        return 0;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value.toString())?.toLocal();

    if (date == null) return value.toString();

    String twoDigits(int number) =>
        number.toString().padLeft(2, '0');

    return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year} '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tracking Tiket')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tracking Tiket')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error ?? 'Data tiket tidak ditemukan',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final status =
        _ticket!['status']?.toString() ?? 'open';
    final currentStep = _getStatusStep(status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Tiket'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTracking,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Stepper(
              currentStep: currentStep,
              physics: const NeverScrollableScrollPhysics(),
              controlsBuilder: (_, __) =>
                  const SizedBox.shrink(),
              steps: [
                Step(
                  title: const Text('Open'),
                  content: const Text(
                    'Tiket dibuat oleh pengguna dan tersimpan di sistem.',
                  ),
                  isActive: currentStep >= 0,
                  state: currentStep > 0
                      ? StepState.complete
                      : StepState.indexed,
                ),
                Step(
                  title: const Text('Assign'),
                  content: const Text(
                    'Admin telah menerima tiket dan memilih helpdesk.',
                  ),
                  isActive: currentStep >= 1,
                  state: currentStep > 1
                      ? StepState.complete
                      : StepState.indexed,
                ),
                Step(
                  title: const Text('In Progress'),
                  content: const Text(
                    'Tiket sedang dikerjakan oleh helpdesk.',
                  ),
                  isActive: currentStep >= 2,
                  state: currentStep > 2
                      ? StepState.complete
                      : StepState.indexed,
                ),
                Step(
                  title: const Text('Close'),
                  content: const Text(
                    'Tiket telah diselesaikan oleh helpdesk.',
                  ),
                  isActive: currentStep >= 3,
                  state: currentStep >= 3
                      ? StepState.complete
                      : StepState.indexed,
                ),
              ],
            ),
            if (_histories.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: Text(
                  'Riwayat Aktivitas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ..._histories.map((history) {
                final action =
                    history['action']?.toString();
                final description =
                    history['description']?.toString();
                final historyStatus =
                    history['status']?.toString() ?? '-';

                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(
                    action != null && action.isNotEmpty
                        ? action
                        : historyStatus.toUpperCase(),
                  ),
                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      if (description != null &&
                          description.isNotEmpty)
                        Text(description),
                      Text(
                        _formatDate(history['created_at']),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
