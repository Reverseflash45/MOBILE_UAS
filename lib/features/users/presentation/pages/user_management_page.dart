import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _supabase
          .from('profiles')
          .select();
          
      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat pengguna: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleUserStatus(String userId, bool currentStatus) async {
    try {
      await _supabase
          .from('profiles')
          .update({'is_active': !currentStatus})
          .eq('id', userId);
          
      _fetchUsers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status pengguna berhasil diubah')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pengguna'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final isActive = user['is_active'] ?? true;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isActive ? Colors.blue : Colors.grey,
                      child: Icon(
                        isActive ? Icons.person : Icons.person_off,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(user['email'] ?? 'No Email'),
                    subtitle: Text('Role: ${user['role'] ?? 'user'}'),
                    trailing: Switch(
                      value: isActive,
                      onChanged: (value) {
                        _toggleUserStatus(user['id'], isActive);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}