import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, bool>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<bool> {
  SettingsNotifier() : super(true) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Default-nya true (nyala) kalau user belum pernah ngatur
    state = prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    state = value;
  }
}