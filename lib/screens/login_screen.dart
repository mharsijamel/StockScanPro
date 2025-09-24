import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_models.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/animation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController(text: 'https://smart.webvue.tn');
  final _dbController = TextEditingController(text: 'SMARTTEST');
  final _loginController = TextEditingController(text: 'contact@example.com');
  final _passwordController = TextEditingController(text: '12345');
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _dbController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(AuthRequest(
      url: _urlController.text,
      database: _dbController.text,
      login: _loginController.text,
      password: _passwordController.text,
    ));

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec authentification')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withAlpha(100),
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Connexion Odoo',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.25),
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        TextFormField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            labelText: 'URL Odoo',
                            prefixIcon: Icon(Icons.link),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _dbController,
                          decoration: InputDecoration(
                            labelText: 'Base de données',
                            prefixIcon: Icon(Icons.storage),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _loginController,
                          decoration: InputDecoration(
                            labelText: 'Login',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 40),
                        if (authProvider.status == AuthStatus.Authenticating)
                          Center(child: CircularProgressIndicator())
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submit,
                              child: const Text('Connexion'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
