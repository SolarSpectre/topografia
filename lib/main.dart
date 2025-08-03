
// Importaciones principales de Flutter, Firebase, Google Maps y utilidades.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'src/utils/spherical_area_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/login_screen.dart';
import 'src/home_screen.dart';

/// Punto de entrada principal de la aplicación.
/// Inicializa Firebase y ejecuta la aplicación principal [MyApp].
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "", // Llena con tu apiKey de Firebase
        appId: "", // Llena con tu appId de Firebase
        messagingSenderId: "", // Llena con tu senderId de Firebase
        projectId: "", // Llena con tu projectId de Firebase
      )
  );
  runApp(const MyApp());
}
//ultimo cambio


/// Widget principal de la aplicación.
/// Determina si el usuario está logueado y muestra la pantalla correspondiente.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Verifica si el usuario está logueado consultando las preferencias compartidas.
  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') != null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Topografia App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Usa FutureBuilder para decidir si mostrar HomeScreen o LoginScreen
      home: FutureBuilder<bool>(
        future: _isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data == true) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}



/// Pantalla principal del mapa.
/// Permite ver la ubicación en tiempo real, dibujar polígonos y guardar áreas en Firestore.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}


class _MapScreenState extends State<MapScreen> {
  // Controlador del mapa de Google
  GoogleMapController? _mapController;
  // Posición inicial del mapa (GooglePlex por defecto)
  static const LatLng _initialPosition = LatLng(37.422, -122.084);
  // Instancia de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Suscripción al stream de ubicación
  StreamSubscription<Position>? _positionStream;
  // ID del usuario actual
  String? _userId;
  // Marcadores de usuarios
  final Set<Marker> _markers = {};
  // Polígonos dibujados en el mapa
  final Set<Polygon> _polygons = {};
  // Puntos actuales del polígono en edición
  List<LatLng> _polygonPoints = [];
  // Marcadores de los puntos del polígono en edición
  Set<Marker> _polygonPointMarkers = {};
  // Estado de dibujo de polígono
  bool _isDrawing = false;
  // Estado de seguimiento de ubicación
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _requestPermissionAndGetLocation();
  }

  /// Carga el userId almacenado en preferencias compartidas.
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  /// Solicita permisos de ubicación y centra el mapa en la ubicación actual si se otorgan.
  void _requestPermissionAndGetLocation() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocationAndAnimateCamera();
    } else if (status.isDenied) {
      // Permiso denegado, se puede mostrar un mensaje al usuario si se desea.
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  /// Obtiene la ubicación actual y mueve la cámara del mapa a esa posición.
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

  /// Inicia el seguimiento de la ubicación y guarda la posición en Firestore en tiempo real.
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

  /// Detiene el seguimiento de la ubicación.
  void _stopLocationUpdates() {
    _positionStream?.cancel();
  }

  /// Callback cuando el mapa es creado.
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }


  /// Construye la interfaz de la pantalla del mapa.
  /// Incluye el mapa, botones de acción y lógica para mostrar marcadores y polígonos.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa en Tiempo Real'),
        actions: [
          // Botón para centrar el mapa en la ubicación actual
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _getCurrentLocationAndAnimateCamera();
            },
          ),
          // Botón para iniciar/detener el seguimiento de ubicación
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
            // Agrega un marcador por cada usuario con ubicación registrada
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

          // StreamBuilder anidado para mostrar polígonos guardados
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

                // Muestra el mapa con los marcadores y polígonos
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
      // Botón flotante para activar/desactivar el modo de dibujo de polígono
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isDrawing = !_isDrawing;
            if (!_isDrawing) {
              // Limpia los puntos si se sale del modo dibujo sin guardar
              _polygonPoints = [];
              _polygonPointMarkers = {};
            }
          });
        },
        child: Icon(_isDrawing ? Icons.close : Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      // Botón para finalizar y guardar el polígono
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


  /// Muestra un diálogo con la información del polígono seleccionado.
  /// Incluye área, perímetro y coordenadas de los vértices.
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


  /// Agrega un punto al polígono en edición y actualiza el mapa.
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
      // Actualiza el polígono en edición
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

  /// Guarda el polígono actual en Firestore si tiene más de 2 puntos.
  /// Calcula el área usando la función utilitaria y muestra un mensaje de confirmación.
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
