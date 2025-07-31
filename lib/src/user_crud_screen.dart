import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_detail_screen.dart';
import 'crud_user.dart';
import 'dart:async';

class UserCrudScreen extends StatefulWidget {
  const UserCrudScreen({super.key});

  @override
  _UserCrudScreenState createState() => _UserCrudScreenState();
}

class _UserCrudScreenState extends State<UserCrudScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  GoogleMapController? _mapController;
  final Map<String, Marker> _markers = {};
  String? _selectedUserId;
  StreamSubscription? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _trackSelectedUser();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _trackSelectedUser() {
    if (_selectedUserId == null) return;
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
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 15));
        }
      } else {
        if (mounted) {
          setState(() {
            _markers.remove(_selectedUserId!);
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            tooltip: 'Administrar usuarios',
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                final data = userDoc.data();
                final role = (data != null && data.containsKey('role')) ? data['role'] : '';
                if (role == 'administrador') {
                  // Acceso permitido
                  // ignore: use_build_context_synchronously
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CrudUserScreen(),
                    ),
                  );
                } else {
                  // Acceso denegado
                  // ignore: use_build_context_synchronously
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
          bool isLargeScreen = constraints.maxWidth > 600;
          if (isLargeScreen) {
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
                leading: StreamBuilder<DocumentSnapshot>(
                  stream: _firestore.collection('locations').doc(userId).snapshots(),
                  builder: (context, locationSnapshot) {
                    bool isOnline = false;
                    if (locationSnapshot.hasData && locationSnapshot.data!.exists) {
                      final data = locationSnapshot.data!.data() as Map<String, dynamic>;
                      if (data.containsKey('timestamp') && data['timestamp'] != null) {
                        final timestamp = (data['timestamp'] as Timestamp).toDate();
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

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildUserList((userId, userEmail) {
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
              target: LatLng(4.60971, -74.08175), // Centered on Colombia
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
