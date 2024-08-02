import 'package:cloud_firestore/cloud_firestore.dart';

class GeoPointHelper {
  static Map<String, double>? toMap(GeoPoint? geoPoint) {
    if (geoPoint == null) return null;
    return {
      'latitude': geoPoint.latitude,
      'longitude': geoPoint.longitude,
    };
  }

  static GeoPoint fromMap(Map<String, dynamic> map) {
    return GeoPoint(map['latitude'], map['longitude']);
  }
}
