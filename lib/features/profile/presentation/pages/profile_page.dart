import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        setState(() {
          _userData = response;
          _userData?['email'] = user.email;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(child: Text('Gagal memuat profil'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.person, size: 50, color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.email),
                              title: const Text('Email'),
                              subtitle: Text(_userData?['email'] ?? '-'),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.badge),
                              title: const Text('Role'),
                              subtitle: Text(
                                (_userData?['role'] ?? 'user').toString().toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: const Text('Nama Lengkap'),
                              subtitle: Text(_userData?['full_name'] ?? 'Belum diatur'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}