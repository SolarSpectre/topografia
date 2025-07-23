import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _error = '';
  bool _loading = false;

  Future<void> _login() async {
    setState(() { _loading = true; _error = ''; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message ?? 'Error de autenticación'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _register() async {
    if (mounted) setState(() { _loading = true; _error = ''; });
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await FirebaseAuth.instance.signOut();
      // Esperar a que el usuario esté realmente deslogueado
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return FirebaseAuth.instance.currentUser != null;
      });
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Cerrar el dialog de carga
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario registrado correctamente')),
        );
        _emailController.clear();
        _passwordController.clear();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() { _error = e.message ?? 'Error al registrar'; });
      }
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading ? const CircularProgressIndicator() : const Text('Iniciar sesión'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _loading ? null : _register,
              child: const Text('Registrarse'),
            ),
          ],
        ),
      ),
    );
  }
}
