import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/dashboard_repository.dart';

class DashboardStatisticWidget extends ConsumerStatefulWidget {
  final String? helpdeskId;

  const DashboardStatisticWidget({
    super.key,
    this.helpdeskId,
  });

  @override
  ConsumerState<DashboardStatisticWidget> createState() =>
      _DashboardStatisticWidgetState();
}

class _DashboardStatisticWidgetState
    extends ConsumerState<DashboardStatisticWidget> {
  late Future<Map<String, int>> _statisticsFuture;

  @override
  void initState() {
    super.initState();
    _statisticsFuture = _loadStatistics();
  }

  Future<Map<String, int>> _loadStatistics() async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      throw Exception('Pengguna belum login');
    }

    final profile = await supabase
        .from('profiles')
        .select('role')
        .eq('id', currentUser.id)
        .single();

    final role = profile['role']
            ?.toString()
            .trim()
            .toLowerCase() ??
        'user';

    return ref
        .read(dashboardRepositoryProvider)
        .getTicketStatistics(
          role: role,
          userId: currentUser.id,
        );
  }

  Future<void> _refreshStatistics() async {
    setState(() {
      _statisticsFuture = _loadStatistics();
    });

    await _statisticsFuture;
  }

  Widget _buildStatCard(
    String title,
    int count,
    Color color,
  ) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: color.withOpacity(0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
          ),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _statisticsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gagal memuat statistik:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _refreshStatistics,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final stats = snapshot.data ??
            {
              'total': 0,
              'open': 0,
              'assign': 0,
              'in progress': 0,
              'closed': 0,
            };

        return RefreshIndicator(
          onRefresh: _refreshStatistics,
          child: ListView(
            shrinkWrap: true,
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Statistik Tiket',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard(
                    'Total',
                    stats['total'] ?? 0,
                    Colors.blueGrey,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    'Open',
                    stats['open'] ?? 0,
                    Colors.red,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    'Assigned',
                    stats['assign'] ?? 0,
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatCard(
                    'In Progress',
                    stats['in progress'] ?? 0,
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    'Closed',
                    stats['closed'] ?? 0,
                    Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}