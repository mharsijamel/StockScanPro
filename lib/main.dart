import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/picking_provider.dart';
import 'providers/scanning_provider.dart';
import 'services/database_service.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/picking_list_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/scanning_screen.dart';
import 'constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final databaseService = DatabaseService();
  await databaseService.initDatabase();
  
  final apiService = ApiService();
  final authService = AuthService(apiService);
  final syncService = SyncService(apiService, databaseService);
  
  runApp(StockScanProApp(
    databaseService: databaseService,
    apiService: apiService,
    authService: authService,
    syncService: syncService,
  ));
}

class StockScanProApp extends StatelessWidget {
  final DatabaseService databaseService;
  final ApiService apiService;
  final AuthService authService;
  final SyncService syncService;

  const StockScanProApp({
    Key? key,
    required this.databaseService,
    required this.apiService,
    required this.authService,
    required this.syncService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService),
        ),
        ChangeNotifierProvider(
          create: (_) => SyncProvider(syncService),
        ),
        ChangeNotifierProvider(
          create: (_) => PickingProvider(databaseService, apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ScanningProvider(databaseService, apiService),
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
        ),
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  late final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/pickings/:type',
        builder: (context, state) {
          final type = state.pathParameters['type']!;
          return PickingListScreen(operationType: type);
        },
      ),
      GoRoute(
        path: '/products/:pickingId',
        builder: (context, state) {
          final pickingId = int.parse(state.pathParameters['pickingId']!);
          return ProductListScreen(pickingId: pickingId);
        },
      ),
      GoRoute(
        path: '/scanning/:pickingId/:productId',
        builder: (context, state) {
          final pickingId = int.parse(state.pathParameters['pickingId']!);
          final productId = int.parse(state.pathParameters['productId']!);
          return ScanningScreen(
            pickingId: pickingId,
            productId: productId,
          );
        },
      ),
    ],
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isLoggedIn = authProvider.isAuthenticated;
      
      if (!isLoggedIn && state.location != '/login' && state.location != '/splash') {
        return '/login';
      }
      
      return null;
    },
  );
}
