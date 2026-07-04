import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'core/router/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'core/network/supabase_client.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS, // <-- Ini yang bener, wajib pakai huruf 'iOS' (i kecil, O besar, S besar)
  );
  
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  await SupabaseClientConfig.initialize();
  
  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'E-Ticketing Helpdesk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: AppRouter.splashRoute,
      routes: AppRouter.routes,
    );
  }
}