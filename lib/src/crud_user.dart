// Pantalla para la gestión (CRUD) de usuarios y administradores.
// Permite crear, listar y eliminar usuarios en Firestore.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbcrypt/dbcrypt.dart';

class CrudUserScreen extends StatefulWidget {
  const CrudUserScreen({super.key});

  // Widget principal de la pantalla CRUD de usuarios.
  @override
  _CrudUserScreenState createState() => _CrudUserScreenState();
}

class _CrudUserScreenState extends State<CrudUserScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  // Variables para mostrar mensajes de error en los campos del formulario.
  String? _emailError;
  String? _passwordError;
  String? _roleError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidRole(String role) {
    return role == 'usuario' || role == 'administrador';
  }

  // Valida el formato del correo electrónico.
  Future<void> _addUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final role = _roleController.text.trim();
    setState(() {
  // Valida que el rol sea 'usuario' o 'administrador'.
      _emailError = null;
      _passwordError = null;
      _roleError = null;
    });
  // Agrega un nuevo usuario a Firestore después de validar los datos y encriptar la contraseña.
    bool valid = true;
    if (email.isEmpty) {
      setState(() {
        _emailError = 'El correo electrónico es obligatorio.';
      });
      valid = false;
    } else if (!_isValidEmail(email)) {
      setState(() {
        _emailError = 'El formato del correo electrónico es incorrecto.';
      });
      valid = false;
    }
    
    if (password.isEmpty) {
      setState(() {
        _passwordError = 'La contraseña es obligatoria.';
      });
      valid = false;
    } else if (password.length < 6) {
      setState(() {
        _passwordError = 'La contraseña debe tener al menos 6 caracteres.';
      });
      valid = false;
    }

    if (role.isEmpty) {
      setState(() {
        _roleError = 'El rol es obligatorio.';
      });
      valid = false;
    } else if (!_isValidRole(role)) {
      setState(() {
        _roleError = 'El rol debe ser "usuario" o "administrador".';
      });
      valid = false;
    }
    if (!valid) return;

    final hashedPassword = DBCrypt().hashpw(password, DBCrypt().gensalt());
    await _firestore.collection('users').add({
      'email': email,
      'password': hashedPassword,
      'role': role,
    });
    _emailController.clear();
    _passwordController.clear();
    _roleController.clear();
    setState(() {
      _emailError = null;
      _passwordError = null;
      _roleError = null;
    });
  }

  Future<void> _deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFe3f0ff),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1976d2),
        title: const Text(
  // Elimina un usuario de Firestore por su ID.
          'CRUD Usuarios/Admins',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.1,
    // Construye la interfaz de usuario principal para la gestión de usuarios.
    // Incluye formulario de registro y lista de usuarios existentes.
          ),
        ),
      ),
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
                    const Icon(Icons.admin_panel_settings, size: 60, color: Color(0xFF1976d2)),
                    const SizedBox(height: 12),
                    const Text(
                      'Gestión de Usuarios/Admins',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976d2),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              errorText: _emailError,
                              filled: true,
                              fillColor: const Color(0xFFeaf4fb),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              labelStyle: const TextStyle(color: Color(0xFF1976d2)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              errorText: _passwordError,
                              filled: true,
                              fillColor: const Color(0xFFeaf4fb),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              labelStyle: const TextStyle(color: Color(0xFF1976d2)),
                            ),
                            obscureText: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _roleController,
                            decoration: InputDecoration(
                              labelText: 'Rol (usuario/administrador)',
                              errorText: _roleError,
                              filled: true,
                              fillColor: const Color(0xFFeaf4fb),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              labelStyle: const TextStyle(color: Color(0xFF1976d2)),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Color(0xFF1976d2)),
                          onPressed: _addUser,
                        ),
                      ],
                    ),
                    if (_emailError != null || _roleError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          children: [
                            if (_emailError != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _emailError!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            if (_roleError != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _roleError!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 350,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('users').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final users = snapshot.data!.docs;
                          return ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final email = user['email'] ?? '';
                              final role = user.data().toString().contains('role') ? user['role'] : 'usuario';
                              return Card(
                                color: const Color(0xFFeaf4fb),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  title: Text(
                                    email,
                                    style: const TextStyle(
                                      color: Color(0xFF1976d2),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text('Rol: $role'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        tooltip: 'Eliminar',
                                        onPressed: () => _deleteUser(user.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
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
