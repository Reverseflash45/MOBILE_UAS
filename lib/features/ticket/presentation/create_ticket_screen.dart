import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/ticket_repository.dart';
import '../../../core/services/storage_service.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() =>
      _CreateTicketScreenState();
}

class _CreateTicketScreenState
    extends ConsumerState<CreateTicketScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null || !mounted) return;

      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }

  Future<void> _submitTicket() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul dan deskripsi tidak boleh kosong'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? attachmentUrl;

      if (_selectedFile != null) {
        attachmentUrl = await StorageService().uploadFile(
          _selectedFile!,
          'ticket_attachments',
        );
      }

      await ref.read(ticketRepositoryProvider).createTicket(
            title: title,
            description: description,
            attachmentUrl: attachmentUrl,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiket berhasil dibuat')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat tiket: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Judul Keluhan',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                minLines: 5,
                maxLines: 8,
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
                onPressed: _isLoading ? null : _pickImage,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  _selectedFile != null
                      ? 'Ganti Lampiran'
                      : 'Tambah Lampiran (Gambar)',
                ),
              ),
              if (_selectedFile != null) ...[
                const SizedBox(height: 8),
                Text(
                  'File: ${_selectedFile!.path.split(Platform.pathSeparator).last}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitTicket,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
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
