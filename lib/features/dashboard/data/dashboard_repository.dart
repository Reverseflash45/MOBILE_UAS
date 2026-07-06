import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final dashboardRepositoryProvider =
    Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

class DashboardRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, int>> getTicketStatistics({
    required String role,
    required String userId,
  }) async {
    dynamic query = _supabase
        .from('tickets')
        .select('status');

    final normalizedRole = role.trim().toLowerCase();

    if (normalizedRole == 'user') {
      query = query.eq('user_id', userId);
    } else if (normalizedRole == 'helpdesk') {
      query = query.eq('assigned_to', userId);
    }

    final response = await query;

    final tickets =
        List<Map<String, dynamic>>.from(response);

    final total = tickets.length;

    final open = tickets.where((ticket) {
      return ticket['status']
              ?.toString()
              .trim()
              .toLowerCase() ==
          'open';
    }).length;

    final assign = tickets.where((ticket) {
      return ticket['status']
              ?.toString()
              .trim()
              .toLowerCase() ==
          'assign';
    }).length;

    final inProgress = tickets.where((ticket) {
      return ticket['status']
              ?.toString()
              .trim()
              .toLowerCase() ==
          'in progress';
    }).length;

    final closed = tickets.where((ticket) {
      return ticket['status']
              ?.toString()
              .trim()
              .toLowerCase() ==
          'close';
    }).length;

    return {
      'total': total,
      'open': open,
      'assign': assign,
      'in progress': inProgress,
      'closed': closed,
    };
  }
}