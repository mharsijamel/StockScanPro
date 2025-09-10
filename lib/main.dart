import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/odoo_login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/stock_in_screen.dart';
import 'screens/stock_out_screen.dart';
import 'screens/scanning_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final apiService = ApiService();
  final authService = AuthService(apiService);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(authService),
        ),
      ],
      child: const StockScanProApp(),
    ),
  );
}

class StockScanProApp extends StatelessWidget {
  const StockScanProApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const OdooLoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/pickings/in',
          builder: (context, state) => const StockInScreen(),
        ),
        GoRoute(
          path: '/pickings/out',
          builder: (context, state) => const StockOutScreen(),
        ),
        GoRoute(
          path: '/scanning/:pickingId/:productId',
          builder: (context, state) {
            final pickingId = int.parse(state.pathParameters['pickingId']!);
            final productId = int.parse(state.pathParameters['productId']!);
            return ScanningScreen(pickingId: pickingId, productId: productId);
          },
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
      ],
      redirect: (context, state) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isLoggedIn = authProvider.isAuthenticated;

        if (!isLoggedIn &&
            state.uri.toString() != '/login' &&
            state.uri.toString() != '/splash') {
          return '/login';
        }

        return null;
      },
    );

    return MaterialApp.router(
      title: 'StockScan Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
