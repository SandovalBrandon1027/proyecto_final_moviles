import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class CalculationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> calculate() async {
    var users = await _firestore.collection('users').get();
    var locations = _getUniqueUserLocations(users.docs);

    if (locations.length == 2) {
      var distance = _calculateDistance(locations[0], locations[1]);
      return {'type': 'distance', 'value': distance.toStringAsFixed(2)};
    } else if (locations.length >= 3) {
      // Ordenar las ubicaciones por su ángulo polar
      locations = _sortLocationsByAngle(locations);
      var perimeter = _calculatePerimeter(locations);
      var area = _calculateArea(locations);
      return {
        'type': 'area',
        'perimeter': perimeter.toStringAsFixed(2),
        'area': area.toStringAsFixed(2)
      };
    } else {
      return {'type': 'error', 'message': 'Not enough locations'};
    }
  }

  List<String> _getUniqueUserLocations(List<QueryDocumentSnapshot> docs) {
    Map<String, String> latestLocations = {};

    for (var doc in docs) {
      String userId = doc.id;
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String? location = data['location'] as String?;
      if (location != null) {
        latestLocations[userId] = location;
      }
    }

    return latestLocations.values.toList();
  }

  List<double> _extractCoordinates(String location) {
    var regex = RegExp(r'(-?\d+\.\d+)');
    var matches = regex.allMatches(location);
    return matches.map((m) => double.parse(m.group(0)!)).toList();
  }

  List<String> _sortLocationsByAngle(List<String> locations) {
    // Calcular el centroide
    double centroidX = 0;
    double centroidY = 0;
    var coordinates = locations.map((loc) => _extractCoordinates(loc)).toList();
    for (var coord in coordinates) {
      centroidX += coord[0];
      centroidY += coord[1];
    }
    centroidX /= coordinates.length;
    centroidY /= coordinates.length;

    // Ordenar por ángulo polar respecto al centroide
    locations.sort((a, b) {
      var coordA = _extractCoordinates(a);
      var coordB = _extractCoordinates(b);

      var angleA = atan2(coordA[1] - centroidY, coordA[0] - centroidX);
      var angleB = atan2(coordB[1] - centroidY, coordB[0] - centroidX);

      return angleA.compareTo(angleB);
    });

    return locations;
  }

  double _calculateDistance(String loc1, String loc2) {
    var coords1 = _extractCoordinates(loc1);
    var coords2 = _extractCoordinates(loc2);

    var lat1 = coords1[0];
    var lon1 = coords1[1];
    var lat2 = coords2[0];
    var lon2 = coords2[1];

    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  double _calculatePerimeter(List<String> locations) {
    double perimeter = 0.0;
    for (var i = 0; i < locations.length; i++) {
      var nextIndex = (i + 1) % locations.length;
      perimeter += _calculateDistance(locations[i], locations[nextIndex]);
    }
    return perimeter;
  }

  double _calculateArea(List<String> locations) {
    // Convertir cadenas de ubicación a coordenadas
    var coords = locations.map((loc) => _extractCoordinates(loc)).toList();

    // Fórmula del zapato para el área del polígono
    double area = 0.0;
    for (var i = 0; i < coords.length; i++) {
      var j = (i + 1) % coords.length;
      area += coords[i][0] * coords[j][1];
      area -= coords[j][0] * coords[i][1];
    }
    area = area.abs() / 2.0;
    return area;
  }
}
