import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../auth/data/auth_repository.dart';

class ListTicketScreen extends ConsumerStatefulWidget {
  const ListTicketScreen({super.key});

  @override
  ConsumerState<ListTicketScreen> createState() =>
      _ListTicketScreenState();
}

class _ListTicketScreenState
    extends ConsumerState<ListTicketScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _tickets = [];

  String? _userRole;
  String? _currentUserId;

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  int _offset = 0;
  static const int _limit = 10;

  @override
  void initState() {
    super.initState();
    _initialize();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMore) {
        _fetchTickets();
      }
    });
  }

  Future<void> _initialize() async {
    final authRepo = ref.read(authRepositoryProvider);
    final user = authRepo.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
      return;
    }

    try {
      final role = await authRepo.getUserRole(user.id);

      _currentUserId = user.id;
      _userRole = role?.toLowerCase();

      await _fetchTickets(reset: true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isInitialLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat tiket: $e')),
      );
    }
  }

  Future<void> _fetchTickets({bool reset = false}) async {
    if (_isLoadingMore) return;

    if (reset) {
      _offset = 0;
      _hasMore = true;
      _tickets.clear();
    }

    if (!_hasMore) return;

    if (mounted) {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      dynamic query =
          Supabase.instance.client.from('tickets').select();

      if (_userRole == 'user') {
        query = query.eq('user_id', _currentUserId!);
      } else if (_userRole == 'helpdesk') {
        query = query.eq('assigned_to', _currentUserId!);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(_offset, _offset + _limit - 1);

      final newTickets = List<Map<String, dynamic>>.from(
        response as List,
      );

      if (!mounted) return;

      setState(() {
        _tickets.addAll(newTickets);
        _offset += newTickets.length;
        _hasMore = newTickets.length == _limit;
        _isInitialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isInitialLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil daftar tiket: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await _fetchTickets(reset: true);
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

  String _getTitle() {
    switch (_userRole) {
      case 'admin':
        return 'Semua Tiket';
      case 'helpdesk':
        return 'Tiket Ditugaskan';
      default:
        return 'Tiket Saya';
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
        title: Text(_getTitle()),
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _tickets.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 240),
                        Center(
                          child: Text(
                            'Belum ada tiket yang tersedia.',
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          _tickets.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _tickets.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final ticket = _tickets[index];
                        final status =
                            ticket['status']?.toString() ??
                                'open';
                        final statusColor =
                            _getStatusColor(status);

                        return Card(
                          margin:
                              const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            title: Text(
                              ticket['title']?.toString() ??
                                  'Tanpa Judul',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              ticket['description']
                                      ?.toString() ??
                                  '-',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(20),
                                border: Border.all(
                                  color: statusColor,
                                ),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            onTap: () async {
                              final changed =
                                  await Navigator.pushNamed(
                                context,
                                AppRouter.detailTicketRoute,
                                arguments: ticket,
                              );

                              if (changed == true) {
                                await _refresh();
                              } else {
                                await _refresh();
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
