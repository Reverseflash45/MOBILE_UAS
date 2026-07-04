import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dashboard_repository.dart';

class DashboardStatisticWidget extends ConsumerWidget {
  final String? helpdeskId;
  
  const DashboardStatisticWidget({super.key, this.helpdeskId});

  Widget _buildStatCard(String title, int count, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: color.withOpacity(0.5), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsFuture = ref.watch(dashboardRepositoryProvider).getTicketStatistics(helpdeskId);

    return FutureBuilder<Map<String, int>>(
      future: statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        final stats = snapshot.data ?? {'total': 0, 'open': 0, 'assign': 0, 'in progress': 0, 'closed': 0};

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statistik Tiket',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard('Total', stats['total'] ?? 0, Colors.blueGrey),
                  const SizedBox(width: 8),
                  _buildStatCard('Open', stats['open'] ?? 0, Colors.red),
                  const SizedBox(width: 8),
                  _buildStatCard('Assigned', stats['assign'] ?? 0, Colors.orange),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatCard('In Progress', stats['in progress'] ?? 0, Colors.green),
                  const SizedBox(width: 8),
                  _buildStatCard('Closed', stats['closed'] ?? 0, Colors.grey),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}