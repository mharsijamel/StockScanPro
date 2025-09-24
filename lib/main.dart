import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/picking_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'utils/theme.dart'; // Import your custom theme

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PickingProvider()),
      ],
      child: MaterialApp(
        title: 'Odoo Stock App',
        theme: appTheme, // Apply your custom theme
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        switch (auth.status) {
          case AuthStatus.Uninitialized:
          case AuthStatus.Authenticating:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.Authenticated:
            return const HomeScreen();
          case AuthStatus.Unauthenticated:
            return const LoginScreen();
        }
      },
    );
  }
}
