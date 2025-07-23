import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapDetailScreen extends StatefulWidget {
  final String userId;
  final String userEmail;

  const MapDetailScreen({
    Key? key,
    required this.userId,
    required this.userEmail,
  }) : super(key: key);

  @override
  _MapDetailScreenState createState() => _MapDetailScreenState();
}

class _MapDetailScreenState extends State<MapDetailScreen> {
  GoogleMapController? _mapController;
  Marker? _userMarker;
  StreamSubscription? _locationSubscription;

  @override
  void initState() {
    super.initState();
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
            _userMarker = Marker(
              markerId: MarkerId(widget.userId),
              position: position,
              infoWindow: InfoWindow(title: widget.userEmail),
            );
          });

          _mapController?.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: position, zoom: 15),
          ));
        }
      }
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

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