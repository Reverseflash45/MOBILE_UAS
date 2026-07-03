import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'ISI_DENGAN_URL_SUPABASE_LU',
      anonKey: 'ISI_DENGAN_ANON_KEY_SUPABASE_LU',
    );
  }

  static final SupabaseClient client = Supabase.instance.client;
}