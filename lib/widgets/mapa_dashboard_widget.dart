import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapaDashboardWidget extends StatefulWidget {
  final String ciudad;

  const MapaDashboardWidget({super.key, required this.ciudad});

  @override
  State<MapaDashboardWidget> createState() => _MapaDashboardWidgetState();
}

class _MapaDashboardWidgetState extends State<MapaDashboardWidget> {
  Map<String, dynamic>? clima;
  bool _cargando = false;

  String _mapaActual = 'relieve'; // 'relieve' o 'satelite'
  final MapController _mapController = MapController();

  final Map<String, LatLng> coordenadasCiudades = {
    'Achupallas': LatLng(-2.4031, -78.7964),
    'Cebadas': LatLng(-2.1951, -78.7750),
    'Palmira': LatLng(-2.2113, -78.7095),
    'Riobamba': LatLng(-1.6636, -78.6546),
  };

  @override
  void initState() {
    super.initState();
    cargarClima();
  }

  @override
  void didUpdateWidget(covariant MapaDashboardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ciudad != oldWidget.ciudad) {
      cargarClima();
    }
  }

  Future<void> cargarClima() async {
    setState(() => _cargando = true);
    try {
      final response = await http.get(Uri.parse(
          'http://localhost:3000/api/openweather?ciudad=${Uri.encodeComponent(widget.ciudad)}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          clima = data;
        });
      }
    } catch (e) {
      debugPrint('❌ Error al obtener clima: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  TileLayer get capaMapa {
    return _mapaActual == 'satelite'
        ? TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: 'com.tesis.alertas',
          )
        : TileLayer(
            urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.tesis.alertas',
          );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng punto = coordenadasCiudades[widget.ciudad] ?? coordenadasCiudades['Achupallas']!;

    return SizedBox(
      height: 340,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: punto,
              zoom: 13,
              maxZoom: 18,
              minZoom: 5,
              interactiveFlags: InteractiveFlag.all,
            ),
            children: [
              capaMapa,
              MarkerLayer(
                markers: [
                  Marker(
                    width: 220,
                    height: 100,
                    point: punto,
                    child: const Icon(Icons.location_on, size: 40, color: Colors.red),
                  ),
                ],
              ),
            ],
          ),
          if (clima != null)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🌡️ ${clima!['temperatura']}°C',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text('💧 ${clima!['humedad']}%', style: const TextStyle(fontSize: 12)),
                    Text('💨 ${clima!['viento']} km/h', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 10,
            left: 10,
            child: Column(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _cargando ? null : cargarClima,
                  icon: const Icon(Icons.refresh),
                  label: Text(_cargando ? 'Cargando...' : 'Actualizar'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade900,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    setState(() {
                      _mapaActual = _mapaActual == 'relieve' ? 'satelite' : 'relieve';
                    });
                  },
                  icon: const Icon(Icons.map),
                  label: Text(_mapaActual == 'relieve' ? 'Ver Satélite' : 'Ver Relieve'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
