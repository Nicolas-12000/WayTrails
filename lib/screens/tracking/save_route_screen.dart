import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class SaveRouteScreen extends StatelessWidget {
  final List<LatLng> routePoints;
  final double distance;
  final int duration;
  final double avgSpeed;

  const SaveRouteScreen({
    super.key,
    required this.routePoints,
    required this.distance,
    required this.duration,
    required this.avgSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Save Route')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distance: ${distance.toStringAsFixed(2)} km'),
            Text('Duration: $duration s'),
            Text('Avg speed: ${avgSpeed.toStringAsFixed(2)} km/h'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Save (placeholder)'),
            ),
          ],
        ),
      ),
    );
  }
}
