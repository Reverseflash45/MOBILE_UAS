import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: const CircleAvatar(
                backgroundColor: Colors.indigo,
                child: Icon(Icons.notifications, color: Colors.white),
              ),
              title: const Text(
                'Pembaruan Sistem',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Status tiket Anda telah diperbarui ke sistem.'),
              trailing: const Text(
                'Baru',
                style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
              ),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}