import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:math';
import '../../services/auth_service.dart';
import 'user_management_page.dart';
import '../../services/auth_service.dart';

class AdminMap extends StatefulWidget {
  const AdminMap({Key? key}) : super(key: key);

  @override
  _AdminMapState createState() => _AdminMapState();
}

class _AdminMapState extends State<AdminMap> {
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  MapController _mapController = MapController();
  StreamSubscription<QuerySnapshot>? _usersStreamSubscription;
  double _area = 0.0;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startListeningToActiveUsers();
  }

  @override
  void dispose() {
    _usersStreamSubscription?.cancel();
    super.dispose();
  }

  void _startListeningToActiveUsers() {
    _usersStreamSubscription = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      _updateMarkers(snapshot.docs);
    });
  }

  void _updateMarkers(List<QueryDocumentSnapshot> docs) {
    setState(() {
      _markers = docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['latitude'] != null && data['longitude'] != null) {
          return Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(data['latitude'], data['longitude']),
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(data['name'] ?? 'Usuario'),
                      content: Text(data['email'] ?? ''),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Cerrar'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: Icon(Icons.location_on, color: Colors.red),
            ),
          );
        }
        return null;
      }).whereType<Marker>().toList();

      _polylines = _createPolylines(_markers.map((marker) => marker.point).toList());
      _area = _calculatePolygonArea(_markers.map((marker) => marker.point).toList());

      if (_markers.isNotEmpty && _mapController.center == null) {
        _mapController.move(_markers.first.point, 13.0);
      }
    });
  }

  List<Polyline> _createPolylines(List<LatLng> points) {
    List<Polyline> polylines = [];

    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        polylines.add(Polyline(
          points: [points[i], points[j]],
          strokeWidth: 2.0,
          color: Colors.blue,
        ));
      }
    }

    return polylines;
  }

  double _calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    double area = 0.0;
    int j = points.length - 1;

    for (int i = 0; i < points.length; i++) {
      LatLng p1 = points[j];
      LatLng p2 = points[i];

      double x1 = _toMeters(p1.latitude, p1.longitude).x;
      double y1 = _toMeters(p1.latitude, p1.longitude).y;
      double x2 = _toMeters(p2.latitude, p2.longitude).x;
      double y2 = _toMeters(p2.latitude, p2.longitude).y;

      area += (x1 * y2) - (x2 * y1);
      j = i;
    }

    return area.abs() / 2.0;
  }

  Point _toMeters(double lat, double lon) {
    const double R = 6378137.0;
    double x = R * lon * pi / 180.0;
    double y = R * log(tan((90.0 + lat) * pi / 360.0));
    return Point(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Mapa de Administrador'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menú de Administrador',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('Cerrar Sesión'),
              onTap: () async {
                await AuthService().signout(context: context);
              },
            ),
            ListTile(
              title: Text("Administrar usuarios"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => UserManagementPage(),
                ));
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _markers.isNotEmpty 
                  ? _markers.first.point 
                  : LatLng(0, 0),
              zoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(markers: _markers),
              PolylineLayer(polylines: _polylines),
            ],
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "btn1",
                  mini: true,
                  child: Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _mapController.move(_mapController.center!, _mapController.zoom + 1);
                    });
                  },
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "btn2",
                  mini: true,
                  child: Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      _mapController.move(_mapController.center!, _mapController.zoom - 1);
                    });
                  },
                ),
              ],
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(8.0),
              child: Text('Área: ${_area.toStringAsFixed(2)} m²'),
            ),
          ),
          if (_isLoading)
            Center(child: CircularProgressIndicator()),
          if (_errorMessage.isNotEmpty)
            Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class Point {
  final double x;
  final double y;

  Point(this.x, this.y);
}