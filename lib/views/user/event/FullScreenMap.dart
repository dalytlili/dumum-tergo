import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class FullScreenMap extends StatelessWidget {
  final LatLng position;
  final String lieu;

  const FullScreenMap({
    Key? key,
    required this.position,
    required this.lieu,
  }) : super(key: key);

  Future<void> _openMaps() async {
    // URL pour Google Maps (iOS)
    final googleMapsUrlIOS = 'comgooglemaps://?daddr=${position.latitude},${position.longitude}&directionsmode=driving';
    
    // URL pour Apple Plans (iOS)
    final appleMapsUrl = 'https://maps.apple.com/?daddr=${position.latitude},${position.longitude}';
    
    // URL pour Google Maps (Android)
    final googleMapsUrlAndroid = 'geo:${position.latitude},${position.longitude}?q=${position.latitude},${position.longitude}($lieu)';

    // Fallback (navigateur web)
    final fallbackUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${position.latitude},${position.longitude}',
    );

    try {
      if (Platform.isIOS) {
        // Essayer d'abord Google Maps sur iOS
        if (await canLaunchUrl(Uri.parse(googleMapsUrlIOS))) {
          await launchUrl(Uri.parse(googleMapsUrlIOS));
        } 
        // Sinon, essayer Apple Plans
        else if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
          await launchUrl(Uri.parse(appleMapsUrl));
        } 
        // Fallback navigateur
        else {
          await launchUrl(fallbackUrl);
        }
      } 
      else if (Platform.isAndroid) {
        // Android: essayer Google Maps en priorité
        if (await canLaunchUrl(Uri.parse(googleMapsUrlAndroid))) {
          await launchUrl(Uri.parse(googleMapsUrlAndroid));
        } 
        // Fallback navigateur
        else {
          await launchUrl(fallbackUrl);
        }
      }
    } catch (e) {
      await launchUrl(fallbackUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lieu),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: position,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: position,
                    width: 80,
                    height: 80,
                    child: const Icon(Icons.location_pin, color: Colors.red, size: 50),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.directions),
              label: const Text('Ouvrir dans Maps'),
              onPressed: _openMaps,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}