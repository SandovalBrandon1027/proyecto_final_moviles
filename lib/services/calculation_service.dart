import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class CalculationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> calculate() async {
    var users = await _firestore.collection('users').get();
    var locations = users.docs.map((doc) => doc.data()['location'] as String).toList();

    if (locations.length == 2) {
      var distance = _calculateDistance(locations[0], locations[1]);
      return {'type': 'distance', 'value': distance};
    } else if (locations.length > 2) {
      var perimeter = _calculatePerimeter(locations);
      var area = _calculateArea(locations);
      return {'type': 'area', 'perimeter': perimeter, 'area': area};
    } else {
      return {'type': 'error', 'message': 'Not enough locations'};
    }
  }

  double _calculateDistance(String loc1, String loc2) {
    var coords1 = _extractCoordinates(loc1);
    var coords2 = _extractCoordinates(loc2);

    var lat1 = coords1[0];
    var lon1 = coords1[1];
    var lat2 = coords2[0];
    var lon2 = coords2[1];

    var p = 0.017453292519943295;
    var a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  List<double> _extractCoordinates(String location) {
    var regex = RegExp(r'(-?\d+\.\d+)');
    var matches = regex.allMatches(location);
    return matches.map((m) => double.parse(m.group(0)!)).toList();
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
    // Convert location strings to coordinates
    var coords = locations.map((loc) => _extractCoordinates(loc)).toList();

    // Shoelace formula for polygon area
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
