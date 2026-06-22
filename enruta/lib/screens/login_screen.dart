import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../main.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  Future<void> _login() async {
    final usuario = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (usuario == 'admin' && password == 'admin123') {
      setState(() => _loading = true);
      try {
        final api = AppServices.instance.apiClient;
        await api.login('admin', 'admin123').timeout(const Duration(seconds: 5));
        await AppServices.instance.syncService.fullSync();
      } catch (_) {
        // sin backend, modo offline
      }
      if (!mounted) return;
      setState(() => _loading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(username: usuario),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Credenciales inválidas'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _devAccess() {
    _usernameController.text = 'admin';
    _passwordController.text = 'admin123';
    _login();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.directions_car,
                  size: 80, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text('EnRuta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface)),
              const SizedBox(height: 8),
              Text('Inicia sesión para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 48),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Iniciar Sesión'),
              ),
              const SizedBox(height: 48),
              TextButton(
                onPressed: _loading ? null : _devAccess,
                child: const Text('Acceso Dev',
                    style: TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.underline)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
