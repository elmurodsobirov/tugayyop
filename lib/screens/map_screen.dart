import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // PK-00 Approximate Location (Tashkent region example)
    final LatLng gateLocation = const LatLng(41.311081, 69.240562); 

    return Scaffold(
      appBar: AppBar(title: const Text('Satellite Map')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: gateLocation,
          initialZoom: 15.0,
        ),
        children: [
          // Esri World Imagery (Satellite)
          TileLayer(
            urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: 'com.example.scada_mobile_app',
          ),
          // Markers
          MarkerLayer(
            markers: [
              Marker(
                point: gateLocation,
                width: 80,
                height: 80,
                child: const Column(
                  children: [
                    Icon(Icons.location_on, color: Colors.red, size: 40),
                    Text("PK-00", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
