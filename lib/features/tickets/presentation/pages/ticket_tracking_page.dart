import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TicketTrackingPage extends StatefulWidget {
  final String ticketId;

  const TicketTrackingPage({super.key, required this.ticketId});

  @override
  State<TicketTrackingPage> createState() => _TicketTrackingPageState();
}

class _TicketTrackingPageState extends State<TicketTrackingPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _histories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistories();
  }

  Future<void> _fetchHistories() async {
    try {
      final response = await _supabase
          .from('ticket_histories')
          .select()
          .eq('ticket_id', widget.ticketId)
          .order('created_at', ascending: false);
          
      setState(() {
        _histories = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Tiket'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _histories.isEmpty
              ? const Center(child: Text('Belum ada riwayat tracking'))
              : ListView.builder(
                  itemCount: _histories.length,
                  itemBuilder: (context, index) {
                    final history = _histories[index];
                    return ListTile(
                      leading: const Icon(Icons.timeline),
                      title: Text('Status: ${history['status']}'),
                      subtitle: Text(history['created_at'].toString()),
                    );
                  },
                ),
    );
  }
}