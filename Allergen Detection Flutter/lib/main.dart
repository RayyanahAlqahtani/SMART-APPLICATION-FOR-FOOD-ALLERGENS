import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'providers/report_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/user/main_app_shell.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() async {
  // Ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Lock orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar color
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<app_auth.AuthProvider>(
          create: (_) => app_auth.AuthProvider(),
        ),
        ChangeNotifierProvider<ReportProvider>(
          create: (_) => ReportProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Smart Allergen Detector',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,

        home: const AuthGate(),
        onGenerateRoute: AppRouter.generateRoute,

        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: child!,
          );
        },
      ),
    );
  }
}

/// Listens to Firebase auth state and AuthProvider user model
/// to route to the correct screen based on login status and role.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Still connecting to Firebase Auth
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not logged in → show login
        if (authSnapshot.data == null) {
          return const LoginScreen();
        }

        // Logged in → check role from AuthProvider
        return Consumer<app_auth.AuthProvider>(
          builder: (context, authProvider, _) {
            final userModel = authProvider.currentUserModel;

            // User model not yet loaded → show loading
            if (userModel == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Route based on role
            if (userModel.role == 'admin') {
              return const AdminDashboardScreen();
            } else {
              return const MainAppShell();
            }
          },
        );
      },
    );
  }
}
