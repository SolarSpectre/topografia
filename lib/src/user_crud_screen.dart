import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_detail_screen.dart';
import 'crud_user.dart';
import 'dart:async';

class UserCrudScreen extends StatefulWidget {
  const UserCrudScreen({Key? key}) : super(key: key);

  @override
  _UserCrudScreenState createState() => _UserCrudScreenState();
}

class _UserCrudScreenState extends State<UserCrudScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  GoogleMapController? _mapController;
  Map<String, Marker> _markers = {};
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
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Administrar usuarios',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CrudUserScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isLargeScreen = constraints.maxWidth > 600;
          if (isLargeScreen) {
            return _buildWideLayout();
          } else {
            return _buildNarrowLayout();
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

            return ListTile(
              title: Tooltip(
                message: userEmail,
                child: Text(userEmail,
                    overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
              leading: StreamBuilder<DocumentSnapshot>(
                stream:
                    _firestore.collection('locations').doc(userId).snapshots(),
                builder: (context, locationSnapshot) {
                  bool isOnline = false;
                  if (locationSnapshot.hasData &&
                      locationSnapshot.data!.exists) {
                    final data =
                        locationSnapshot.data!.data() as Map<String, dynamic>;
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
                icon: const Icon(Icons.location_on),
                onPressed: () => onUserSelected(userId, userEmail),
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
