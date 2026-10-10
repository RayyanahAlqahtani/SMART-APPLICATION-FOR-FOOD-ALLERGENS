import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/user/main_app_shell.dart';
import '../screens/user/scan_camera_screen.dart';
import '../screens/user/result_screen.dart';
import '../screens/user/history_screen.dart';
import '../screens/user/profile_screen.dart';
import '../screens/user/settings_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/manage_users_screen.dart';
import '../screens/admin/manage_allergens_screen.dart';
import '../screens/admin/manage_reports_screen.dart';
import '../screens/user/submit_report_screen.dart';

class PathConstants {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String scan = '/scan';
  static const String result = '/result';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminLogin = '/admin/login';
  static const String adminUsers = '/admin/users';
  static const String adminAllergens = '/admin/allergens';
  static const String adminReports = '/admin/reports';
  static const String userReport = '/report';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case PathConstants.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      // case PathConstants.adminLogin:
      //   return MaterialPageRoute(builder: (_) => const AdminLoginScreen());
      case PathConstants.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case PathConstants.home:
        return MaterialPageRoute(builder: (_) => const MainAppShell());
      case PathConstants.scan:
        return MaterialPageRoute(builder: (_) => const ScanCameraScreen());
      case PathConstants.result:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ResultScreen(),
        );
      case PathConstants.history:
        final args = settings.arguments as Map<String, dynamic>?;
        final showUnsafeOnly = args?['showUnsafeOnly'] ?? false;
        return MaterialPageRoute(
          builder: (_) => HistoryScreen(showUnsafeOnly: showUnsafeOnly),
        );
      case PathConstants.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case PathConstants.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case PathConstants.adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case PathConstants.adminUsers:
        return MaterialPageRoute(builder: (_) => const ManageUsersScreen());
      case PathConstants.adminAllergens:
        return MaterialPageRoute(builder: (_) => const ManageAllergensScreen());
      case PathConstants.adminReports:
        return MaterialPageRoute(builder: (_) => const ManageReportsScreen());
      case PathConstants.userReport:
        return MaterialPageRoute(builder: (_) => const SubmitReportScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
