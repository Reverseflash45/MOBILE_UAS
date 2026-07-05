import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'core/router/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'core/network/supabase_client.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  await runZonedGuarded(() async {
    try {
      debugPrint('Mulai inisialisasi notifikasi...');

      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const initializationSettingsIOS =
          DarwinInitializationSettings();

      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      final notificationResult =
          await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      );

      debugPrint('Notifikasi berhasil: $notificationResult');
    } catch (error, stackTrace) {
      debugPrint('ERROR NOTIFIKASI: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      debugPrint('Mulai inisialisasi Supabase...');

      await SupabaseClientConfig.initialize()
          .timeout(const Duration(seconds: 15));

      debugPrint('Supabase berhasil diinisialisasi');
    } catch (error, stackTrace) {
      debugPrint('ERROR SUPABASE: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    debugPrint('Menjalankan runApp...');

    runApp(
      const ProviderScope(
        child: MainApp(),
      ),
    );
  }, (error, stackTrace) {
    debugPrint('ERROR GLOBAL: $error');
    debugPrintStack(stackTrace: stackTrace);
  });
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