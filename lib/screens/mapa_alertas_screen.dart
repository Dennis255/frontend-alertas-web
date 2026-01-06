import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapaAlertasScreen extends StatefulWidget {
  final String ubicacion;
  final String? tipoAlerta;
  final String? nivelAlerta;

  const MapaAlertasScreen({
    super.key,
    required this.ubicacion,
    this.tipoAlerta,
    this.nivelAlerta,
  });

  @override
  State<MapaAlertasScreen> createState() => _MapaAlertasScreenState();
}

class _MapaAlertasScreenState extends State<MapaAlertasScreen> {
  // Controlador para manejar el zoom
  final MapController _mapController = MapController();

  Color _getColorForAlertLevel(String? nivel) {
    switch (nivel?.toLowerCase().trim()) {
      case 'alto':
        return Colors.red; // ISO: Peligro
      case 'medio':
        return Colors.amber; // ISO: Precaución
      case 'bajo':
        return Colors.green; // ISO: Seguridad
      default:
        return Colors.grey;
    }
  }

  Future<void> _openInExternalMaps(LatLng point) async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${point.latitude},${point.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'No se pudo abrir $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final partes = widget.ubicacion.split(',');
    final double lat = double.tryParse(partes[0]) ?? 0.0;
    final double lon = double.tryParse(partes.length > 1 ? partes[1] : '0.0') ?? 0.0;
    final punto = LatLng(lat, lon);
    final alertColor = _getColorForAlertLevel(widget.nivelAlerta);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tipoAlerta != null
            ? "Alerta de ${widget.tipoAlerta}"
            : "Ubicación de Alerta"),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        actions: [
          if (widget.nivelAlerta != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Text(
                widget.nivelAlerta!.toUpperCase(),
                style: const TextStyle(
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
              center: punto,
              zoom: 15.0,
              maxZoom: 18.0,
              minZoom: 5.0,
            ),
            children: [
              // ================== MAPA CORREGIDO AQUÍ ==================
              TileLayer(
                // Usamos ArcGIS World Topo Map (Relieve estable)
                urlTemplate:
                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.example.alerta_temprana',
                // Eliminamos tileProvider complejo innecesario para ArcGIS
              ),
              // ========================================================

              MarkerLayer(
                markers: [
                  Marker(
                    point: punto,
                    width: 60,
                    height: 60,
                    child: Icon(
                      Icons.location_on,
                      color: alertColor,
                      size: 50,
                    ),
                  ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'Esri, USGS | OpenStreetMap',
                    onTap: () => launchUrl(
                        Uri.parse('https://www.esri.com/en-us/legal/copyright-trademarks')),
                  ),
                ],
              ),
            ],
          ),
          
          // Tarjeta de información (Bottom)
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.tipoAlerta != null)
                      Text(
                        'Tipo: ${widget.tipoAlerta}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Coordenadas: $lat, $lon',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _openInExternalMaps(punto),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Abrir en Google Maps'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botones de Zoom (Top Right)
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomIn',
                  onPressed: () {
                    _mapController.move(_mapController.center, _mapController.zoom + 1);
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Color(0xFF1976D2)),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOut',
                  onPressed: () {
                    _mapController.move(_mapController.center, _mapController.zoom - 1);
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Color(0xFF1976D2)),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mapController.move(punto, 15.0);
        },
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}