import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart'; // al inicio del archivo

class PublicAlertaDetalleScreen extends StatelessWidget {
  final Map alerta;

  const PublicAlertaDetalleScreen({super.key, required this.alerta});

  List<String> _generarRecomendaciones(String tipo, String nivel) {
    final List<String> r = [];
    tipo = tipo.toLowerCase();
    nivel = nivel.toLowerCase();

    if (tipo.contains('lluvia')) {
      r.add("ODS 11: Evita zonas inundables para proteger ciudades.");
      r.add("ODS 13: Refuerza techos y estructuras ante lluvias fuertes.");
      if (nivel == 'alto') r.add("ODS 3: Prepara rutas de evacuación seguras.");
    } else if (tipo.contains('helada')) {
      r.add("ODS 2: Protege cultivos sensibles con coberturas térmicas.");
      r.add("ODS 13: Usa riego nocturno como control de temperatura.");
      if (nivel == 'alto') r.add("ODS 1: Coordina ayuda a agricultores.");
    } else if (tipo.contains('sequía')) {
      r.add("ODS 6: Promueve riego por goteo.");
      r.add("ODS 12: Reutiliza agua de lluvia.");
      if (nivel == 'alto') r.add("ODS 13: Activa planes de emergencia hídrica.");
    } else if (tipo.contains('viento')) {
      r.add("ODS 9: Revisa infraestructura crítica.");
      r.add("ODS 11: Asegura techos y estructuras comunitarias.");
    }

    return r;
  }

  Widget _buildInfoCard(String icon, String title, String value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.blue.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, 
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ubicacionStr = alerta['ubicacion'] ?? '-2.4844,-78.8451';
    final coord = ubicacionStr.split(',');
    final LatLng? punto = coord.length == 2
        ? LatLng(double.tryParse(coord[0]) ?? 0.0, double.tryParse(coord[1]) ?? 0.0)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle Público de Alerta'),
        backgroundColor: const Color(0xFF3366CC),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alerta['tipo'] ?? '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3366CC),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Nivel: ${alerta['nivel'] ?? ''}",
                        style: TextStyle(
                          fontSize: 18,
                          color: _getNivelColor(alerta['nivel']),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              _buildInfoCard("📍", "Ubicación", alerta['ubicacion'] ?? ''),
              _buildInfoCard("📅", "Fecha", alerta['fecha']?.toString().split('T')[0] ?? ''),
              
              if (alerta['descripcion'] != null)
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.blue.shade100, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text("📝", style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Text("Descripción",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(alerta['descripcion'] ?? '',
                            textAlign: TextAlign.justify,
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 8),
              
              if (alerta['temperatura'] != null)
                _buildInfoCard("🌡️", "Temperatura", "${alerta['temperatura']}°C"),
              if (alerta['humedad'] != null)
                _buildInfoCard("💧", "Humedad", "${alerta['humedad']}%"),
              if (alerta['precipitacion'] != null)
                _buildInfoCard("🌧️", "Precipitación", "${alerta['precipitacion']} mm"),
              if (alerta['viento'] != null)
                _buildInfoCard("💨", "Velocidad del viento", "${alerta['viento']} km/h"),
              
              const SizedBox(height: 20),
              
              if (punto != null)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 220,
                      child: FlutterMap(
                        options: MapOptions(center: punto, zoom: 13),
                        children: [
                          TileLayer(
                            urlTemplate:
                                "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
                            subdomains: ['a', 'b', 'c'],
                            userAgentPackageName: 'com.tesis.alertas',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: punto,
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.location_on, 
                                    color: Colors.red, 
                                    size: 40),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🛡️ Recomendaciones alineadas a los ODS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF3366CC),
                          )),
                      const SizedBox(height: 12),
                      ..._generarRecomendaciones(alerta['tipo'] ?? '', alerta['nivel'] ?? '')
                          .map((msg) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("• ", 
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.blue,
                                        )),
                                    Expanded(
                                      child: Text(msg,
                                          style: const TextStyle(fontSize: 16)),
                                    ),
                                  ],
                                ),
                              )),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNivelColor(String? nivel) {
    switch (nivel?.toLowerCase()) {
      case 'alto':
        return Colors.red;
      case 'medio':
        return Colors.orange;
      case 'bajo':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}