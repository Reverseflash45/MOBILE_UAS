import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardStatisticWidget extends StatefulWidget {
  const DashboardStatisticWidget({super.key});

  @override
  State<DashboardStatisticWidget> createState() => _DashboardStatisticWidgetState();
}

class _DashboardStatisticWidgetState extends State<DashboardStatisticWidget> {
  final _supabase = Supabase.instance.client;
  Map<String, int> _stats = {
    'total': 0,
    'open': 0,
    'assigned': 0,
    'resolved': 0,
    'closed': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    try {
      final response = await _supabase.from('tickets').select('status');
      final tickets = List<Map<String, dynamic>>.from(response);

      int open = 0, assigned = 0, resolved = 0, closed = 0;

      for (var t in tickets) {
        final status = t['status']?.toString().toLowerCase();
        if (status == 'open') open++;
        else if (status == 'assigned' || status == 'in_progress') assigned++;
        else if (status == 'resolved') resolved++;
        else if (status == 'closed') closed++;
      }

      if (mounted) {
        setState(() {
          _stats = {
            'total': tickets.length,
            'open': open,
            'assigned': assigned,
            'resolved': resolved,
            'closed': closed,
          };
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

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
              _buildStatCard('Total', _stats['total']!, Colors.blueGrey),
              const SizedBox(width: 8),
              _buildStatCard('Open', _stats['open']!, Colors.red),
              const SizedBox(width: 8),
              _buildStatCard('Assigned', _stats['assigned']!, Colors.orange),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatCard('Resolved', _stats['resolved']!, Colors.green),
              const SizedBox(width: 8),
              _buildStatCard('Closed', _stats['closed']!, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}