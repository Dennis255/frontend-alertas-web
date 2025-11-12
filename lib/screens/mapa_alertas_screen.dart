import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart'; // Añade esta importación
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';


class MapaAlertasScreen extends StatelessWidget {
  final String ubicacion;
  final String? tipoAlerta;
  final String? nivelAlerta;

  const MapaAlertasScreen({
    super.key,
    required this.ubicacion,
    this.tipoAlerta,
    this.nivelAlerta,
  });

  Color _getColorForAlertLevel(String? nivel) {
    switch (nivel?.toLowerCase()) {
      case 'alto':
        return Colors.red;
      case 'medio':
        return Colors.orange;
      case 'bajo':
        return Colors.yellow;
      default:
        return Colors.blue;
    }
  }

  Future<void> _openInExternalMaps(LatLng point) async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${point.latitude},${point.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'No se pudo abrir $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final partes = ubicacion.split(',');
    final double lat = double.tryParse(partes[0]) ?? 0.0;
    final double lon = double.tryParse(partes[1]) ?? 0.0;
    final punto = LatLng(lat, lon);
    final alertColor = _getColorForAlertLevel(nivelAlerta);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            tipoAlerta != null ? "Alerta de $tipoAlerta" : "Ubicación de Alerta"),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 4,
        actions: [
          if (nivelAlerta != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: alertColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: alertColor, width: 1),
              ),
              child: Text(
                nivelAlerta!.toUpperCase(),
                style: TextStyle(
                  color: alertColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: punto,
              zoom: 15.0,
              maxZoom: 18.0,
              minZoom: 5.0,
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
                    'OpenStreetMap contributors',
                    onTap: () => launchUrl(
                        Uri.parse('https://openstreetmap.org/copyright')),
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tipoAlerta != null)
                      Text(
                        'Tipo: $tipoAlerta',
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
                      label: const Text('Abrir en Maps'),
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
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomIn',
                  onPressed: () {
                    // Lógica para zoom in
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Color(0xFF1976D2)),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOut',
                  onPressed: () {
                    // Lógica para zoom out
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
          // Lógica para centrar mapa
        },
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}