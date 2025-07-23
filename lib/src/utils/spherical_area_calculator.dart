import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const double earthRadius = 6371000; // Earth's radius in meters

double calculateSphericalPolygonArea(List<LatLng> points) {
  if (points.length < 3) {
    return 0;
  }

  double area = 0;
  for (int i = 0; i < points.length; i++) {
    final p1 = points[i];
    final p2 = points[(i + 1) % points.length];

    final lat1 = p1.latitude * (pi / 180);
    final lon1 = p1.longitude * (pi / 180);
    final lat2 = p2.latitude * (pi / 180);
    final lon2 = p2.longitude * (pi / 180);

    area += (lon2 - lon1) * (2 + sin(lat1) + sin(lat2));
  }

  area = area * earthRadius * earthRadius / 2;
  return area.abs();
} 