import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yürüme Uygulaması',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late TextEditingController _kmController = TextEditingController();
  late Location _location = Location();
  late GoogleMapController _mapController;
  LatLng? _currentLocation;
  LatLng? _targetLocation;
  Set<Polyline> _polylines = {};
  String _googleApiKey = 'AIzaSyDe2sZXfyEyWQVFaxHY7-E7TewO2Dxvu9w';

  @override
  void initState() {
    super.initState();
    _location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        _currentLocation = LatLng(
            currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0);
      });
    });
  }

  void _generateRandomLocation(double km) {
    if (_currentLocation != null) {
      double randomAngle = Random().nextDouble() * 2 * pi;
      double randomDistance =
          km / 111.12; // 1 degree of latitude is approximately 111.12 km
      double dx = randomDistance * cos(randomAngle);
      double dy = randomDistance * sin(randomAngle);
      _targetLocation = LatLng(
          _currentLocation!.latitude + dx, _currentLocation!.longitude + dy);
      _getDirections();
    }
  }

  void _getDirections() async {
    if (_currentLocation != null && _targetLocation != null) {
      final polylinePoints = PolylinePoints();
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        _googleApiKey,
        PointLatLng(_currentLocation!.latitude, _currentLocation!.longitude),
        PointLatLng(_targetLocation!.latitude, _targetLocation!.longitude),
        travelMode: TravelMode.walking,
      );
      if (result.points.isNotEmpty) {
        List<LatLng> polylineCoordinates = [];
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
        _polylines = {
          Polyline(
            polylineId: PolylineId('route'),
            color: Colors.red,
            width: 5,
            points: polylineCoordinates,
          ),
          Polyline(
            polylineId: PolylineId('markers_line'),
            color: Colors.blue,
            width: 5,
            points: [_currentLocation!, _targetLocation!],
          ),
        };
        setState(() {});
      }
    }
  }

  List<LatLng> polylineToLatLng(String polyline) {
    List<LatLng> polylinePoints = [];
    List<String> polylineArray = polyline.split(',');
    for (int i = 0; i < polylineArray.length; i += 2) {
      polylinePoints.add(LatLng(
        double.parse(polylineArray[i]),
        double.parse(polylineArray[i + 1]),
      ));
    }
    return polylinePoints;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yürüme Uygulaması'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _kmController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Bugün kaç km yürümek istiyorsunuz?',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                double km = double.tryParse(_kmController.text) ?? 0.0;
                _generateRandomLocation(km);
                _mapController
                    .animateCamera(CameraUpdate.newLatLng(_targetLocation!));
              },
              child: Text('Konumu Göster'),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                    target: _currentLocation ?? LatLng(0.0, 0.0), zoom: 15),
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                markers: {
                  if (_currentLocation != null)
                    Marker(
                      markerId: MarkerId('currentLocation'),
                      position: _currentLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue),
                    ),
                  if (_targetLocation != null)
                    Marker(
                      markerId: MarkerId('target'),
                      position: _targetLocation!,
                    ),
                },
                polylines: _polylines,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
