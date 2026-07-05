import 'package:flutter/material.dart';

import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';

import '../../features/dashboard/presentation/admin_dashboard_screen.dart';
import '../../features/dashboard/presentation/helpdesk_dashboard_screen.dart';
import '../../features/dashboard/presentation/user_dashboard_screen.dart';

import '../../features/ticket/presentation/create_ticket_screen.dart';
import '../../features/ticket/presentation/list_ticket_screen.dart';

import '../../features/tickets/presentation/pages/ticket_detail_page.dart';
import '../../features/tickets/presentation/pages/ticket_tracking_page.dart';

import '../../features/users/presentation/pages/user_management_page.dart';
import '../../features/manage_users/presentation/add_user_screen.dart';

import '../../features/notifications/presentation/pages/notification_page.dart';

import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/setting_page.dart';

class AppRouter {
  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String resetPasswordRoute = '/reset-password';

  static const String adminDashboardRoute =
      '/admin-dashboard';
  static const String helpdeskDashboardRoute =
      '/helpdesk-dashboard';
  static const String userDashboardRoute =
      '/user-dashboard';

  static const String createTicketRoute = '/create-ticket';
  static const String listTicketRoute = '/list-ticket';
  static const String detailTicketRoute = '/detail-ticket';
  static const String trackingTicketRoute =
      '/tracking-ticket';

  static const String userListRoute = '/user-list';
  static const String addUserRoute = '/add-user';
  static const String notificationRoute = '/notification';
  static const String profileRoute = '/profile';
  static const String settingRoute = '/setting';

  static Map<String, WidgetBuilder> get routes {
    return {
      splashRoute: (context) => const SplashScreen(),

      loginRoute: (context) => const LoginScreen(),

      registerRoute: (context) => const RegisterScreen(),

      resetPasswordRoute: (context) =>
          const ForgotPasswordPage(),

      adminDashboardRoute: (context) =>
          const AdminDashboardScreen(),

      helpdeskDashboardRoute: (context) =>
          const HelpdeskDashboardScreen(),

      userDashboardRoute: (context) =>
          const UserDashboardScreen(),

      createTicketRoute: (context) =>
          const CreateTicketScreen(),

      listTicketRoute: (context) =>
          const ListTicketScreen(),

      detailTicketRoute: (context) {
        final arguments =
            ModalRoute.of(context)?.settings.arguments;

        if (arguments is! Map<String, dynamic>) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Data tiket tidak ditemukan',
              ),
            ),
          );
        }

        return TicketDetailPage(
          ticket: arguments,
        );
      },

      trackingTicketRoute: (context) {
        final arguments =
            ModalRoute.of(context)?.settings.arguments;

        String? ticketId;

        if (arguments is String) {
          ticketId = arguments;
        } else if (arguments is Map<String, dynamic>) {
          ticketId = arguments['id']?.toString();
        }

        if (ticketId == null || ticketId.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text(
                'ID tiket tidak ditemukan',
              ),
            ),
          );
        }

        return TicketTrackingPage(
          ticketId: ticketId,
        );
      },

      userListRoute: (context) =>
          const UserManagementPage(),

      addUserRoute: (context) =>
          const AddUserScreen(),

      notificationRoute: (context) =>
          const NotificationPage(),

      profileRoute: (context) =>
          const ProfilePage(),

      settingRoute: (context) =>
          const SettingPage(),
    };
  }
}