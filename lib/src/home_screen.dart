
// Importaciones principales para la pantalla de inicio (panel principal)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:topografia/src/login_screen.dart';
import '../main.dart';
import 'user_crud_screen.dart';


/// Pantalla principal de la aplicación tras iniciar sesión.
/// Muestra el panel de bienvenida, opciones de navegación y permite cerrar sesión.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  // Email del usuario autenticado (se muestra en el saludo)
  String _userEmail = 'Usuario';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Carga el email del usuario autenticado desde Firestore usando el userId guardado en preferencias.
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        setState(() {
          _userEmail = userDoc.data()?['email'] ?? 'Usuario';
        });
      }
    }
  }


  /// Construye la interfaz del panel principal.
  /// Muestra el saludo, el botón de cerrar sesión y las opciones de navegación.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFe3f0ff),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1976d2),
        title: Text(
          'Bienvenido, $_userEmail',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.1,
          ),
        ),
        actions: [
          // Botón para cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('userId');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
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
                    // Icono principal
                    const Icon(Icons.home, size: 60, color: Color(0xFF1976d2)),
                    const SizedBox(height: 12),
                    // Título del panel
                    const Text(
                      'Panel Principal',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976d2),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Opciones de navegación
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildDashboardCard(
                            context,
                            icon: Icons.map,
                            label: 'Mapa',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const MapScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDashboardCard(
                            context,
                            icon: Icons.people,
                            label: 'Gestión de Usuarios',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const UserCrudScreen()),
                              );
                            },
                          ),
                        ),
                      ],
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

  /// Construye una tarjeta de opción del panel principal.
  /// Recibe un icono, un texto y una acción al pulsar.
  Widget _buildDashboardCard(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 6,
        color: const Color(0xFFeaf4fb),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: const Color(0xFF1976d2)),
              const SizedBox(height: 16),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976d2),
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
