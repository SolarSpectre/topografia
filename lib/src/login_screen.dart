import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
//Ultima version
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
      if (!mounted) return;
      setState(() { _error = e.message ?? 'Error de autenticación'; });
    } finally {
      if (!mounted) return;
      setState(() { _loading = false; });
    }
  }

  Future<void> _register() async {
    setState(() { _loading = true; _error = ''; });
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await _createUserDocument(userCredential.user);
      // The StreamBuilder should handle navigation, but as a fallback, we navigate manually.
      // This also ensures that this screen is unmounted, cleaning up the loading state.
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to register: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _createUserDocument(User? user) async {
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'uid': user.uid,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFe3f0ff),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 10,
              color: const Color(0xFFf5faff),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_pin_circle, size: 60, color: Color(0xFF1976d2)),
                    const SizedBox(height: 12),
                    const Text(
                      'Iniciar Sesión',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976d2),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1976d2)),
                        labelText: 'Email',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFeaf4fb),
                        labelStyle: const TextStyle(color: Color(0xFF1976d2)),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1976d2)),
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFeaf4fb),
                        labelStyle: const TextStyle(color: Color(0xFF1976d2)),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    if (_error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_error, style: const TextStyle(color: Colors.red)),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.login, color: Colors.white),
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976d2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        label: _loading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Iniciar sesión', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF1976d2)),
                        onPressed: _loading ? null : _register,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1976d2)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        label: _loading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1976d2)))
                            : const Text('Registrarse', style: TextStyle(fontSize: 16, color: Color(0xFF1976d2)))),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
