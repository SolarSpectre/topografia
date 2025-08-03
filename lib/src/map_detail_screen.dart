
// Importaciones principales para la pantalla de detalle de mapa.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


/// Pantalla que muestra la ubicación en tiempo real de un usuario específico en Google Maps.
/// Recibe el userId y el email del usuario a mostrar.
class MapDetailScreen extends StatefulWidget {
  final String userId;
  final String userEmail;

  const MapDetailScreen({
    super.key,
    required this.userId,
    required this.userEmail,
  });

  @override
  _MapDetailScreenState createState() => _MapDetailScreenState();
}


class _MapDetailScreenState extends State<MapDetailScreen> {
  // Controlador del mapa de Google
  GoogleMapController? _mapController;
  // Marcador de la ubicación del usuario
  Marker? _userMarker;
  // Suscripción al stream de Firestore para la ubicación
  StreamSubscription? _locationSubscription;

  @override
  void initState() {
    super.initState();
    // Se suscribe a los cambios en la ubicación del usuario en Firestore
    _locationSubscription = FirebaseFirestore.instance
        .collection('locations')
        .doc(widget.userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final lat = data['latitude'];
        final lng = data['longitude'];
        final position = LatLng(lat, lng);

        if (mounted) {
          setState(() {
            // Actualiza el marcador con la nueva posición
            _userMarker = Marker(
              markerId: MarkerId(widget.userId),
              position: position,
              infoWindow: InfoWindow(title: widget.userEmail),
            );
          });

          // Centra la cámara en la nueva posición
          _mapController?.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: position, zoom: 15),
          ));
        }
      }
    });
  }

  @override
  void dispose() {
    // Cancela la suscripción al stream al cerrar la pantalla
    _locationSubscription?.cancel();
    super.dispose();
  }


  /// Construye la interfaz de la pantalla de detalle de mapa.
  /// Muestra el mapa centrado en la ubicación del usuario y actualiza en tiempo real.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ubicación de ${widget.userEmail}')),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(0, 0),
          zoom: 2,
        ),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        markers: _userMarker != null ? {_userMarker!} : {},
      ),
    );
  }
}