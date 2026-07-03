import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../data/ticket_repository.dart';

class ListTicketScreen extends ConsumerWidget {
  const ListTicketScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketStream = ref.watch(ticketRepositoryProvider).getTicketsStream();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tiket'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ticketStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.indigo));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          
          final tickets = snapshot.data ?? [];
          
          if (tickets.isEmpty) {
            return const Center(child: Text('Belum ada tiket yang tersedia.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
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
                    Navigator.pushNamed(
                      context,
                      AppRouter.detailTicketRoute,
                      arguments: ticket,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}