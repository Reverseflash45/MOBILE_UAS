import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/app_router.dart';
import '../data/ticket_repository.dart';

class ListTicketScreen extends ConsumerStatefulWidget {
  const ListTicketScreen({super.key});

  @override
  ConsumerState<ListTicketScreen> createState() => _ListTicketScreenState();
}

class _ListTicketScreenState extends ConsumerState<ListTicketScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent && !_isLoading && _hasMore) {
        _fetchTickets();
      }
    });
  }

  Future<void> _fetchTickets() async {
    setState(() => _isLoading = true);
    try {
      final newTickets = await ref.read(ticketRepositoryProvider).getTicketsPaginated(_limit, _offset);
      
      setState(() {
        _offset += newTickets.length;
        _tickets.addAll(newTickets);
        if (newTickets.length < _limit) {
          _hasMore = false;
        }
      });
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open': return Colors.blue;
      case 'assign': return Colors.orange;
      case 'in progress': return Colors.purple;
      case 'close': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tiket'),
      ),
      body: _tickets.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : _tickets.isEmpty
              ? const Center(child: Text('Belum ada tiket yang tersedia.'))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _tickets.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _tickets.length) {
                      return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                    }

                    final ticket = _tickets[index];
                    final status = ticket['status']?.toString() ?? 'open';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        title: Text(
                          ticket['title']?.toString() ?? 'Tanpa Judul',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          ticket['description']?.toString() ?? '-',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _getStatusColor(status)),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, AppRouter.detailTicketRoute, arguments: ticket);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}