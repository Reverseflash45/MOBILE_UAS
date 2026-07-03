import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../auth/data/auth_repository.dart';
import '../data/ticket_repository.dart';

class DetailTicketScreen extends ConsumerStatefulWidget {
  const DetailTicketScreen({super.key});

  @override
  ConsumerState<DetailTicketScreen> createState() => _DetailTicketScreenState();
}

class _DetailTicketScreenState extends ConsumerState<DetailTicketScreen> {
  String? _userRole;
  List<Map<String, dynamic>> _helpdeskUsers = [];
  String? _selectedHelpdeskId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final authRepo = ref.read(authRepositoryProvider);
    final user = authRepo.currentUser;
    if (user != null) {
      final role = await authRepo.getUserRole(user.id);
      if (mounted) {
        setState(() => _userRole = role);
      }
      if (role == 'admin') {
        final users = await ref.read(ticketRepositoryProvider).getHelpdeskUsers();
        if (mounted) {
          setState(() => _helpdeskUsers = users);
        }
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Tiket')),
        body: const Center(child: Text('Data tidak ditemukan')),
      );
    }

    final ticketId = args['id'].toString();
    final title = args['title']?.toString() ?? '-';
    final description = args['description']?.toString() ?? '-';
    final status = args['status']?.toString() ?? 'open';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tiket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline),
            onPressed: () {
              Navigator.pushNamed(
                context, 
                AppRouter.trackingTicketRoute,
                arguments: args,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status Saat Ini:',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Chip(
                          label: Text(
                            status.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: _getStatusColor(status),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_userRole == 'admin' && status == 'open')
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() => _isLoading = true);
                        await ref.read(ticketRepositoryProvider).acceptTicket(ticketId);
                        if (mounted) {
                          setState(() => _isLoading = false);
                          Navigator.pop(context);
                        }
                      },
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Terima Tiket'),
              ),
            if (_userRole == 'admin' && status == 'assign')
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedHelpdeskId,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Helpdesk',
                      prefixIcon: Icon(Icons.support_agent),
                    ),
                    items: _helpdeskUsers.map((user) {
                      return DropdownMenuItem<String>(
                        value: user['id'].toString(),
                        child: Text(user['full_name'].toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedHelpdeskId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: (_isLoading || _selectedHelpdeskId == null)
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            await ref.read(ticketRepositoryProvider).assignTicket(ticketId, _selectedHelpdeskId!);
                            if (mounted) {
                              setState(() => _isLoading = false);
                              Navigator.pop(context);
                            }
                          },
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Tugaskan'),
                  ),
                ],
              ),
            if (_userRole == 'helpdesk' && status == 'in progress')
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() => _isLoading = true);
                        await ref.read(ticketRepositoryProvider).closeTicket(ticketId);
                        if (mounted) {
                          setState(() => _isLoading = false);
                          Navigator.pop(context);
                        }
                      },
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Selesai / Finish'),
              ),
          ],
        ),
      ),
    );
  }
}