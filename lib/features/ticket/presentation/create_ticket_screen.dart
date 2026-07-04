import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/ticket_repository.dart';
import '../../../core/services/storage_service.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitTicket() async {
    if (_titleController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan deskripsi tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? attachmentUrl;
      
      if (_selectedFile != null) {
        attachmentUrl = await StorageService().uploadFile(_selectedFile!, 'ticket_attachments');
      }

      await ref.read(ticketRepositoryProvider).createTicket(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        attachmentUrl: attachmentUrl,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiket berhasil dibuat')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Tiket Baru'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Keluhan',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Detail',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.description),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.attach_file),
                label: Text(_selectedFile != null ? 'Ganti Lampiran' : 'Tambah Lampiran (Gambar)'),
              ),
              if (_selectedFile != null) ...[
                const SizedBox(height: 8),
                Text('File: ${_selectedFile!.path.split('/').last}', style: const TextStyle(fontSize: 12, color: Colors.green)),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitTicket,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}