import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final dashboardRepositoryProvider = Provider((ref) => DashboardRepository());

class DashboardRepository {
  final _supabase = Supabase.instance.client;

  Future<Map<String, int>> getTicketStatistics(String? helpdeskId) async {
    dynamic query = _supabase.from('tickets').select();
    
    if (helpdeskId != null) {
      query = _supabase.from('tickets').select().eq('assigned_to', helpdeskId);
    }
    
    final response = await query;
    final tickets = List<Map<String, dynamic>>.from(response);

    int total = tickets.length;
    int open = tickets.where((t) => t['status'] == 'open').length;
    int assign = tickets.where((t) => t['status'] == 'assign').length;
    int inProgress = tickets.where((t) => t['status'] == 'in progress').length;
    int closed = tickets.where((t) => t['status'] == 'close').length;

    return {
      'total': total,
      'open': open,
      'assign': assign,
      'in progress': inProgress,
      'closed': closed,
    };
  }
}