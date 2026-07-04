import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final String _bucketName = 'attachments';

  Future<String?> uploadFile(File file, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final fullPath = '$folder/$fileName';

      await _supabase.storage.from(_bucketName).upload(
        fullPath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(fullPath);
      return publicUrl;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteFile(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(_bucketName);
      
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from(_bucketName).remove([filePath]);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}