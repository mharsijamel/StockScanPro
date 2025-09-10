import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String _loadingMessage = 'Vérification de la connexion...';
  bool _showError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
    ));

    _animationController.forward();
    
    // Delay initialization slightly to allow animation to start
    Future.delayed(const Duration(seconds: 1), _initializeApp);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;

    setState(() {
      _showError = false;
      _loadingMessage = 'Vérification du serveur Odoo...';
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    final healthResult = await apiService.healthCheck();

    if (!mounted) return;

    switch (healthResult) {
      case HealthCheckResult.ok:
        setState(() {
          _loadingMessage = 'Vérification de l\'utilisateur...';
        });
        await _checkAuthenticationStatus();
        break;
      case HealthCheckResult.notFound:
        context.go('/backend-error');
        break;
      case HealthCheckResult.networkError:
        setState(() {
          _showError = true;
          _errorMessage = 'Erreur de réseau. Veuillez vérifier votre connexion internet et réessayer.';
        });
        break;
      case HealthCheckResult.unknownError:
        setState(() {
          _showError = true;
          _errorMessage = 'Une erreur inconnue est survenue. Veuillez réessayer.';
        });
        break;
    }
  }

  Future<void> _checkAuthenticationStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final isAuthenticated = await authProvider.checkAuthenticationStatus();
      if (!mounted) return;
      
      if (isAuthenticated) {
        context.go('/dashboard');
      } else {
        context.go('/login');
      }
    } catch (e) {
      // If there's an error (e.g. invalid token), go to login
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo/Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        size: 60,
                        color: Colors.blue,
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // App Name
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // App Subtitle
                    Text(
                      'Gestion des numéros de série',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Loading/Error content
                    _buildStatusContent(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusContent() {
    if (_showError) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.yellow[200], fontSize: 16),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            onPressed: _initializeApp,
            style: ElevatedButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
              backgroundColor: Colors.white,
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            _loadingMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      );
    }
  }
}
