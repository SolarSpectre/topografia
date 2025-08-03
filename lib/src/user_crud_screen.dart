
/// Pantalla principal para la gestión y visualización de usuarios y sus ubicaciones en el mapa.
/// Permite a los administradores acceder a la gestión CRUD de usuarios y a cualquier usuario visualizar la ubicación de otros usuarios en tiempo real.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'map_detail_screen.dart';
import 'crud_user.dart';
import 'dart:async';


/// Widget principal de la pantalla de gestión de usuarios.
class UserCrudScreen extends StatefulWidget {
  const UserCrudScreen({super.key});

  @override
  _UserCrudScreenState createState() => _UserCrudScreenState();
}


/// Estado asociado a [UserCrudScreen].
/// Maneja la lógica de suscripción a Firestore, control del mapa y selección de usuarios.
class _UserCrudScreenState extends State<UserCrudScreen> {
  /// Instancia de Firestore para acceder a la base de datos en la nube.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Controlador del mapa de Google para manipular la cámara y otros aspectos.
  GoogleMapController? _mapController;

  /// Marcadores actuales mostrados en el mapa, indexados por el ID de usuario.
  final Map<String, Marker> _markers = {};

  /// ID del usuario actualmente seleccionado para seguimiento en el mapa.
  String? _selectedUserId;

  /// Suscripción activa al stream de ubicación del usuario seleccionado.
  StreamSubscription? _locationSubscription;


  @override
  void initState() {
    super.initState();
    // Inicia el seguimiento de la ubicación del usuario seleccionado (si existe uno al inicio).
    _trackSelectedUser();
  }


  @override
  void dispose() {
    // Cancela la suscripción al stream de ubicación para evitar fugas de memoria.
    _locationSubscription?.cancel();
    super.dispose();
  }
//2-------------------------------------------
  /// Inicia o reinicia la suscripción a la ubicación del usuario seleccionado.
  /// Cada vez que cambian los datos de ubicación en Firestore, actualiza el marcador en el mapa.
  void _trackSelectedUser() {
    if (_selectedUserId == null) return;
    // Cancela cualquier suscripción previa para evitar múltiples listeners.
    _locationSubscription?.cancel();
    _locationSubscription = _firestore
        .collection('locations')
        .doc(_selectedUserId!)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final lat = data['latitude'];
        final lng = data['longitude'];
        final position = LatLng(lat, lng);

        // Crea un marcador para la ubicación actual del usuario.
        final marker = Marker(
          markerId: MarkerId(_selectedUserId!),
          position: position,
          infoWindow: InfoWindow(
              title: 'Ubicación del usuario',
              snippet: 'Lat: $lat, Lng: $lng'),
        );

        if (mounted) {
          setState(() {
            _markers[_selectedUserId!] = marker;
          });
          // Centra la cámara en la nueva ubicación.
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 15));
        }
      } else {
        // Si el documento de ubicación ya no existe, elimina el marcador.
        if (mounted) {
          setState(() {
            _markers.remove(_selectedUserId!);
          });
        }
      }
    });
  }
//3------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Estructura principal de la pantalla, con AppBar y contenido adaptable a tamaño de pantalla.
    return Scaffold(
      backgroundColor: const Color(0xFFe3f0ff),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1976d2),
        title: const Text(
          'Gestión de Usuarios',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.1,
          ),
        ),
        actions: [
          // Botón para acceder a la administración de usuarios (solo para administradores).
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            tooltip: 'Administrar usuarios',
            onPressed: () async {
              // Obtiene el ID del usuario desde SharedPreferences.
              final prefs = await SharedPreferences.getInstance();
              final userId = prefs.getString('userId');
              if (userId != null) {
                // Consulta el rol del usuario en Firestore.
                final userDoc = await _firestore.collection('users').doc(userId).get();
                final data = userDoc.data();
                final role = (data != null && data.containsKey('role')) ? data['role'] : '';
                if (role == 'administrador') {
                  // Si es administrador, navega a la pantalla CRUD de usuarios.
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CrudUserScreen(),
                    ),
                  );
                } else {
                  // Si no es administrador, muestra un diálogo de acceso denegado.
                  if (!mounted) return;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Acceso denegado'),
                      content: const Text('TU NO TIENES PERMISOS SUFICIENTES PARA ESTA FUNCION'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cerrar'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Volver'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Adapta el layout según el ancho de pantalla (responsive).
          bool isLargeScreen = constraints.maxWidth > 600;
          if (isLargeScreen) {
            // Layout para pantallas grandes: lista de usuarios y mapa en paralelo.
            return Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFf5faff),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildWideLayout(),
              ),
            );
          } else {
            // Layout para pantallas pequeñas: solo lista de usuarios.
            return Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFf5faff),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildNarrowLayout(),
              ),
            );
          }
        },
      ),
    );
  }
//1 -----------------------------------------------------------------------------------------------
  /// Construye la lista de usuarios con su estado (online/offline) y botón para ver ubicación.
  /// [onUserSelected] es el callback que se ejecuta al seleccionar un usuario.
  Widget _buildUserList(Function(String, String) onUserSelected) {
    return StreamBuilder<QuerySnapshot>(
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
            final userEmail = user['email'] ?? 'No email';
            final userId = user.id;

            // Tarjeta de usuario con indicador de estado y botón de ubicación.
            return Card(
              color: const Color(0xFFeaf4fb),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Tooltip(
                  message: userEmail,
                  child: Text(
                    userEmail,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Color(0xFF1976d2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Indicador de estado online/offline basado en el timestamp de ubicación.
                leading: StreamBuilder<DocumentSnapshot>(
                  stream: _firestore.collection('locations').doc(userId).snapshots(),
                  builder: (context, locationSnapshot) {
                    bool isOnline = false;
                    if (locationSnapshot.hasData && locationSnapshot.data!.exists) {
                      final data = locationSnapshot.data!.data() as Map<String, dynamic>;
                      if (data.containsKey('timestamp') && data['timestamp'] != null) {
                        final timestamp = (data['timestamp'] as Timestamp).toDate();
                        // Considera online si la última actualización fue hace menos de 5 minutos.
                        if (DateTime.now().difference(timestamp).inMinutes < 5) {
                          isOnline = true;
                        }
                      }
                    }
                    return CircleAvatar(
                      backgroundColor: isOnline ? Colors.green : Colors.grey,
                      radius: 8,
                    );
                  },
                ),
                // Botón para ver la ubicación del usuario en el mapa.
                trailing: IconButton(
                  icon: const Icon(Icons.location_on, color: Color(0xFF1976d2)),
                  onPressed: () => onUserSelected(userId, userEmail),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Layout para pantallas grandes: muestra la lista de usuarios y el mapa en paralelo.
  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildUserList((userId, userEmail) {
            // Al seleccionar usuario, actualiza el seguimiento y los marcadores.
            setState(() {
              _selectedUserId = userId;
              _markers.clear();
              _trackSelectedUser();
            });
          }),
        ),
        Expanded(
          flex: 3,
          child: GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(4.60971, -74.08175), // Centrado en Colombia
              zoom: 5,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            markers: Set<Marker>.of(_markers.values),
          ),
        ),
      ],
    );
  }

  /// Layout para pantallas pequeñas: solo muestra la lista de usuarios.
  /// Al seleccionar un usuario, navega a una pantalla de detalle de mapa.
  Widget _buildNarrowLayout() {
    return _buildUserList((userId, userEmail) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapDetailScreen(
            userId: userId,
            userEmail: userEmail,
          ),
        ),
      );
    });
  }
}
