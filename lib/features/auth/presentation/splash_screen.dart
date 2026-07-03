import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../data/auth_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authRepository = ref.read(authRepositoryProvider);
    final user = authRepository.currentUser;

    if (user != null) {
      final role = await authRepository.getUserRole(user.id);
      if (!mounted) return;
      
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, AppRouter.adminDashboardRoute);
      } else if (role == 'helpdesk') {
        Navigator.pushReplacementNamed(context, AppRouter.helpdeskDashboardRoute);
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.userDashboardRoute);
      }
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Colors.indigo,
        ),
      ),
    );
  }
}