import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://otgdedgfwrzdsxvvsuep.supabase.co',
      anonKey: 'sb_publishable_DFHjPAdZdp460dMNFu7RjA_ryQyg4qN',
    );
  }

  static final SupabaseClient client = Supabase.instance.client;
}