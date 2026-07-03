import 'package:flutter/material.dart';

import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/dashboard/presentation/admin_dashboard_screen.dart';
import '../../features/dashboard/presentation/helpdesk_dashboard_screen.dart';
import '../../features/dashboard/presentation/user_dashboard_screen.dart';
import '../../features/ticket/presentation/create_ticket_screen.dart';
import '../../features/ticket/presentation/list_ticket_screen.dart';
import '../../features/ticket/presentation/detail_ticket_screen.dart';
import '../../features/ticket/presentation/tracking_ticket_screen.dart';
import '../../features/manage_users/presentation/user_list_screen.dart';
import '../../features/manage_users/presentation/add_user_screen.dart';
import '../../features/notification/presentation/notification_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/setting/presentation/setting_screen.dart';

class AppRouter {
  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String resetPasswordRoute = '/reset-password';
  static const String adminDashboardRoute = '/admin-dashboard';
  static const String helpdeskDashboardRoute = '/helpdesk-dashboard';
  static const String userDashboardRoute = '/user-dashboard';
  static const String createTicketRoute = '/create-ticket';
  static const String listTicketRoute = '/list-ticket';
  static const String detailTicketRoute = '/detail-ticket';
  static const String trackingTicketRoute = '/tracking-ticket';
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
      resetPasswordRoute: (context) => const ResetPasswordScreen(),
      adminDashboardRoute: (context) => const AdminDashboardScreen(),
      helpdeskDashboardRoute: (context) => const HelpdeskDashboardScreen(),
      userDashboardRoute: (context) => const UserDashboardScreen(),
      createTicketRoute: (context) => const CreateTicketScreen(),
      listTicketRoute: (context) => const ListTicketScreen(),
      detailTicketRoute: (context) => const DetailTicketScreen(),
      trackingTicketRoute: (context) => const TrackingTicketScreen(),
      userListRoute: (context) => const UserListScreen(),
      addUserRoute: (context) => const AddUserScreen(),
      notificationRoute: (context) => const NotificationScreen(),
      profileRoute: (context) => const ProfileScreen(),
      settingRoute: (context) => const SettingScreen(),
    };
  }
}