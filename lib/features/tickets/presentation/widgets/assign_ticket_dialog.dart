import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final helpdeskUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await Supabase.instance.client
      .from('profiles')
      .select('id, name')
      .eq('role', 'helpdesk');
  return List<Map<String, dynamic>>.from(response);
});

class AssignTicketDialog extends ConsumerStatefulWidget {
  final String ticketId;

  const AssignTicketDialog({super.key, required this.ticketId});

  @override
  ConsumerState<AssignTicketDialog> createState() => _AssignTicketDialogState();
}

class _AssignTicketDialogState extends ConsumerState<AssignTicketDialog> {
  String? selectedHelpdeskId;
  bool isLoading = false;

  Future<void> assignTicket() async {
    if (selectedHelpdeskId == null) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      await Supabase.instance.client.from('tickets').update({
        'assigned_to': selectedHelpdeskId,
        'status': 'assigned'
      }).eq('id', widget.ticketId);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tiket berhasil diteruskan ke Helpdesk!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal meneruskan tiket: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final helpdeskAsync = ref.watch(helpdeskUsersProvider);

    return AlertDialog(
      title: const Text('Teruskan Tiket'),
      content: helpdeskAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Text('Tidak ada akun Helpdesk yang tersedia.');
          }
          return DropdownButtonFormField<String>(
            isExpanded: true,
            hint: const Text('Pilih Petugas Helpdesk'),
            value: selectedHelpdeskId,
            items: users.map((u) {
              return DropdownMenuItem<String>(
                value: u['id'].toString(),
                child: Text(u['name'].toString()),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                selectedHelpdeskId = val;
              });
            },
          );
        },
        loading: () => const SizedBox(
          height: 50, 
          child: Center(child: CircularProgressIndicator())
        ),
        error: (err, stack) => Text('Error: $err'),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: isLoading || selectedHelpdeskId == null ? null : assignTicket,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 16, 
                  height: 16, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                )
              : const Text('Teruskan'),
        ),
      ],
    );
  }
}