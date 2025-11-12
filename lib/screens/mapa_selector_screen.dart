import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';


class MapaSelectorScreen extends StatefulWidget {
  const MapaSelectorScreen({super.key});

  @override
  State<MapaSelectorScreen> createState() => _MapaSelectorScreenState();
}

class _MapaSelectorScreenState extends State<MapaSelectorScreen> {
  LatLng? _puntoSeleccionado;
  final MapController _mapController = MapController();
  double _zoom = 13.0;

  void _onTapMapa(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _puntoSeleccionado = latlng;
    });
  }

  void _confirmarUbicacion() {
    if (_puntoSeleccionado != null) {
      Navigator.pop(context, _puntoSeleccionado);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una ubicación'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _zoomIn() {
    setState(() {
      _zoom += 1;
      _mapController.move(_mapController.center, _zoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom -= 1;
      _mapController.move(_mapController.center, _zoom);
    });
  }

  void _centerMap() {
    if (_puntoSeleccionado != null) {
      _mapController.move(_puntoSeleccionado!, _zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Selecciona una ubicación",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 4,
        actions: [
          TextButton(
            onPressed: _confirmarUbicacion,
            child: const Text(
              "CONFIRMAR",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: const LatLng(-2.3398, -78.4352),
              zoom: _zoom,
              onTap: _onTapMapa,
              maxZoom: 18,
              minZoom: 5,
            ),
            children: [
              TileLayer(
  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
  subdomains: const ['a', 'b', 'c'],
  userAgentPackageName: 'com.example.alerta_temprana',
  tileProvider: CancellableNetworkTileProvider(), // ✅ cambio aquí
  tileBuilder: (context, widget, tile) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.blue.shade100.withOpacity(0.1),
        BlendMode.darken,
      ),
      child: widget,
    );
  },
),

              if (_puntoSeleccionado != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _puntoSeleccionado!,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ubicación seleccionada:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _puntoSeleccionado != null
                          ? "Lat: ${_puntoSeleccionado!.latitude.toStringAsFixed(5)}\nLon: ${_puntoSeleccionado!.longitude.toStringAsFixed(5)}"
                          : "No seleccionada",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomIn',
                  onPressed: _zoomIn,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Color(0xFF1976D2)),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOut',
                  onPressed: _zoomOut,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Color(0xFF1976D2)),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerMap,
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}