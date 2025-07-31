import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'src/utils/spherical_area_calculator.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'src/login_screen.dart';
import 'src/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBJMUpW1XXZovTRRS-RAiIMcc-YR3D5xPs",
        appId: "1:515020313650:web:7d3688d99fec26b64ed82b",
        messagingSenderId: "515020313650",
        projectId: "a-f5b30",
      )
  );
  runApp(const MyApp());
}
//ultimo cambio

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Topografia App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  static const LatLng _initialPosition = LatLng(37.422, -122.084); // Default to GooglePlex
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionStream;
  String? _userId;
  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};
  List<LatLng> _polygonPoints = [];
  Set<Marker> _polygonPointMarkers = {};
  bool _isDrawing = false;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _requestPermissionAndGetLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _requestPermissionAndGetLocation() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocationAndAnimateCamera();
    } else if (status.isDenied) {
      // Handle denied permissions
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void _getCurrentLocationAndAnimateCamera() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.0,
          ),
        ),
      );
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void _startLocationUpdates() {
    final locationSettings = defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Topografia App',
              notificationText: 'Tracking your location in the background',
              enableWakeLock: true,
            ),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (_isTracking && _userId != null) {
        _firestore.collection('locations').doc(_userId!).set({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  void _stopLocationUpdates() {
    _positionStream?.cancel();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa en Tiempo Real'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _getCurrentLocationAndAnimateCamera();
            },
      ),
          IconButton(
            icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
            onPressed: () {
              setState(() {
                _isTracking = !_isTracking;
                if (_isTracking) {
                  _startLocationUpdates();
                } else {
                  _stopLocationUpdates();
                }
              });
            },
            ),
          ],
        ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('locations').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _markers.clear();
            for (var doc in snapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              var marker = Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(data['latitude'], data['longitude']),
                infoWindow: InfoWindow(title: 'User ${doc.id}'),
              );
              _markers.add(marker);
            }
          }

          return StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('polygons').snapshots(),
              builder: (context, polygonSnapshot) {
                if (polygonSnapshot.hasData) {
                  _polygons.clear();
                  for (var doc in polygonSnapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    List<dynamic> points = data['points'];
                    List<LatLng> polygonPoints = points
                        .map((p) => LatLng(p['latitude'], p['longitude']))
                        .toList();

                    _polygons.add(
                      Polygon(
                        polygonId: PolygonId(doc.id),
                        points: polygonPoints,
                        strokeWidth: 2,
                        strokeColor: Colors.red,
                        fillColor: Colors.red.withOpacity(0.3),
                        consumeTapEvents: true,
                        onTap: () => _showPolygonInfo(polygonPoints, data['area']),
                      ),
                    );
                  }
                }

                return GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: const CameraPosition(
                    target: _initialPosition,
                    zoom: 15,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  markers: _markers.union(_polygonPointMarkers),
                  polygons: _polygons,
                  onTap: _isDrawing ? _addPolygonPoint : null,
                );
              });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isDrawing = !_isDrawing;
            if (!_isDrawing) {
              // Clear points when exiting drawing mode without saving
              _polygonPoints = [];
              _polygonPointMarkers = {};
            }
          });
        },
        child: Icon(_isDrawing ? Icons.close : Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      persistentFooterButtons: _isDrawing
          ? [
              TextButton(
                child: const Text('Finalizar Poligono'),
                onPressed: () {
                  _savePolygon();
                },
              )
            ]
          : null,
    );
  }

  void _showPolygonInfo(List<LatLng> points, num area) {
    num perimeter = 0;
    for (int i = 0; i < points.length; i++) {
      perimeter += Geolocator.distanceBetween(
          points[i].latitude,
          points[i].longitude,
          points[(i + 1) % points.length].latitude,
          points[(i + 1) % points.length].longitude);
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detalles del Terreno'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Area: ${area.toStringAsFixed(2)} m²'),
                Text('Perimetro: ${perimeter.toStringAsFixed(2)} m'),
                const SizedBox(height: 10),
                const Text('Vertices:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...points.asMap().entries.map((entry) {
                  int idx = entry.key;
                  LatLng point = entry.value;
                  return Text('  Punto ${idx + 1}: (${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)})');
                }),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addPolygonPoint(LatLng point) {
    setState(() {
      _polygonPoints.add(point);
      _polygonPointMarkers.add(
        Marker(
          markerId: MarkerId('polygon_point_${_polygonPoints.length}'),
          position: point,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
      _polygons.removeWhere((p) => p.polygonId.value == 'current');
      _polygons.add(
        Polygon(
          polygonId: const PolygonId('current'),
          points: _polygonPoints,
          strokeWidth: 2,
          strokeColor: Colors.blue,
          fillColor: Colors.blue.withOpacity(0.3),
        ),
      );
    });
  }

  void _savePolygon() {
    if (_polygonPoints.length > 2) {
      final area = calculateSphericalPolygonArea(_polygonPoints);

      if (_userId != null) {
      _firestore.collection('polygons').add({
        'points': _polygonPoints.map((p) => {'latitude': p.latitude, 'longitude': p.longitude}).toList(),
        'area': area,
        'user': _userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Polygon saved! Area: ${area.toStringAsFixed(2)} m²')),
      );
    }
    setState(() {
      _polygonPoints = [];
      _polygonPointMarkers = {};
      _isDrawing = false;
      _polygons.removeWhere((p) => p.polygonId.value == 'current');
    });
  }
}
