
// Importaciones principales para la pantalla de login y registro.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';


/// Pantalla de inicio de sesión y registro de usuario.
/// Permite a los usuarios autenticarse o crear una cuenta nueva.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}


class _LoginScreenState extends State<LoginScreen> {
  // Controladores para los campos de email y contraseña
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // Mensaje de error general
  String _error = '';
  // Estado de carga para mostrar indicador de progreso
  bool _loading = false;
  // Mensajes de error específicos para los campos
  String? _emailError;
  String? _passwordError;

  /// Valida el formato del correo electrónico usando una expresión regular.
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }


  /// Inicia sesión con el correo y contraseña proporcionados.
  /// Valida los campos, consulta Firestore y verifica la contraseña con bcrypt.
  /// Si es exitoso, guarda el userId en preferencias y navega a HomeScreen.
  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = '';
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    bool valid = true;

    // Validación de campos
    if (email.isEmpty) {
      _emailError = 'El correo electrónico es obligatorio.';
      valid = false;
    } else if (!_isValidEmail(email)) {
      _emailError = 'El formato del correo electrónico es incorrecto.';
      valid = false;
    }

    if (password.isEmpty) {
      _passwordError = 'La contraseña es obligatoria.';
      valid = false;
    }

    if (!valid) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      // Busca el usuario en Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Usuario no encontrado');
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();

      // Verifica la contraseña usando bcrypt
      if (!DBCrypt().checkpw(password, userData['password'])) {
        throw Exception('Contraseña incorrecta');
      }

      // Guarda el userId en preferencias compartidas
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userDoc.id);

      // Navega a la pantalla principal si está montado
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }


  /// Registra un nuevo usuario con email y contraseña.
  /// Valida los campos, verifica que el email no exista, encripta la contraseña y guarda el usuario en Firestore.
  /// Si es exitoso, guarda el userId y navega a HomeScreen.
  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = '';
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    bool valid = true;

    // Validación de campos
    if (email.isEmpty) {
      _emailError = 'El correo electrónico es obligatorio.';
      valid = false;
    } else if (!_isValidEmail(email)) {
      _emailError = 'El formato del correo electrónico es incorrecto.';
      valid = false;
    }

    if (password.isEmpty) {
      _passwordError = 'La contraseña es obligatoria.';
      valid = false;
    } else if (password.length < 6) {
      _passwordError = 'La contraseña debe tener al menos 6 caracteres.';
      valid = false;
    }

    if (!valid) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      // Verifica que el email no esté registrado
      final existingUser = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception('El correo electrónico ya está en uso');
      }

      // Encripta la contraseña y guarda el usuario
      final hashedPassword = DBCrypt().hashpw(password, DBCrypt().gensalt());
      final userRef = await FirebaseFirestore.instance.collection('users').add({
        'email': email,
        'password': hashedPassword,
        'role': 'usuario',
      });

      // Guarda el userId en preferencias compartidas
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userRef.id);

      // Navega a la pantalla principal si está montado
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al registrarse: $e';
          _loading = false;
        });
      }
    }
  }



  /// Construye la interfaz de usuario para login y registro.
  /// Incluye validación visual, mensajes de error y botones de acción.
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
                    // Icono superior
                    const Icon(Icons.person_pin_circle, size: 60, color: Color(0xFF1976D2)),
                    const SizedBox(height: 12),
                    // Título
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
                    // Campo de email
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1976d2)),
                        labelText: 'Email',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFeaf4fb),
                        labelStyle: const TextStyle(color: Color(0xFF1976d2)),
                        errorText: _emailError,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    // Campo de contraseña
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1976d2)),
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFeaf4fb),
                        labelStyle: const TextStyle(color: Color(0xFF1976d2)),
                        errorText: _passwordError,
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    // Mensaje de error general
                    if (_error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_error, style: const TextStyle(color: Colors.red)),
                      ),
                    // Botón de iniciar sesión
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
                    // Botón de registro
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
                            : const Text('Registrarse', style: TextStyle(fontSize: 16, color: Color(0xFF1976d2))),
                      ),
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
