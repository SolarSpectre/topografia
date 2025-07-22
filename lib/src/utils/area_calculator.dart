import 'package:google_maps_flutter/google_maps_flutter.dart';

double calculatePolygonArea(List<LatLng> polygonPoints) {
  if (polygonPoints.length < 3) {
    return 0;
  }

  double area = 0.0;
  for (int i = 0; i < polygonPoints.length; i++) {
    LatLng p1 = polygonPoints[i];
    LatLng p2 = polygonPoints[(i + 1) % polygonPoints.length];
    area += (p1.latitude * p2.longitude) - (p2.latitude * p1.longitude);
  }

  return area.abs() / 2.0;
} 