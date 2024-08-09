import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math';
import '../../services/auth_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<QuerySnapshot>? _usersStreamSubscription;
  double _area = 0.0;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _getCurrentLocation();
    _startListeningToLocationUpdates();
    _startListeningToActiveUsers();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _usersStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = 'Los permisos de ubicación fueron denegados';
        });
      }
    }
  }

  void _startListeningToLocationUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        _updateUserLocation(position);
        setState(() {
          // ignore: deprecated_member_use
          _mapController.move(LatLng(position.latitude, position.longitude), _mapController.zoom);
        });
      },
    );
  }

  void _updateUserLocation(Position position) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
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
                          child: const Text('Cerrar'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Icon(Icons.location_on, color: Colors.red),
            ),
          );
        }
        return null;
      }).whereType<Marker>().toList();

      _polylines = _createPolylines(_markers.map((marker) => marker.point).toList());
      _area = _calculatePolygonArea(_markers.map((marker) => marker.point).toList());
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

  void _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _mapController.move(LatLng(position.latitude, position.longitude), 13.0);
        
        // Añadir un marcador para la ubicación del usuario
        _markers.add(Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(position.latitude, position.longitude),
          child: const Icon(Icons.person_pin, color: Colors.red, size: 40),
        ));
        _isLoading = false;
      });
      
      // Actualizar la ubicación en Firestore
      _updateUserLocation(position);
      
      // Actualizar los marcadores
      _startListeningToActiveUsers();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error al obtener la ubicación actual: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mapa'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
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
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menú',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Cerrar Sesión'),
              onTap: () async {
                await AuthService().signout(context: context);
              },
            ),
          ],
        ),
      ),

      body: Stack(
        children: [
          GestureDetector(
            onTapUp: (TapUpDetails details) {
              final RenderBox renderBox = context.findRenderObject() as RenderBox;
              final point = renderBox.globalToLocal(details.globalPosition);
              // ignore: deprecated_member_use
              final latlng = _mapController.pointToLatLng(CustomPoint(point.dx, point.dy));
              setState(() {
                _markers.add(Marker(
                  width: 80.0,
                  height: 80.0,
                  point: latlng,
                  child: const Icon(Icons.location_on, color: Colors.red),
                ));
              });
            },
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                // ignore: deprecated_member_use
                center: _markers.isNotEmpty 
                    ? _markers.first.point 
                    : const LatLng(0, 0),
                // ignore: deprecated_member_use
                zoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(markers: _markers),
                PolylineLayer(polylines: _polylines),
              ],
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "btn1",
                  mini: true,
                  child: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      // ignore: deprecated_member_use
                      _mapController.move(_mapController.center, _mapController.zoom + 1);
                    });
                  },
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "btn2",
                  mini: true,
                  child: const Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      // ignore: deprecated_member_use
                      _mapController.move(_mapController.center, _mapController.zoom - 1);
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
              padding: const EdgeInsets.all(8.0),
              child: Text('Área: ${_area.toStringAsFixed(2)} m²'),
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          if (_errorMessage.isNotEmpty)
            Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red))),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "btn3",
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

class Point {
  final double x;
  final double y;

  Point(this.x, this.y);
}