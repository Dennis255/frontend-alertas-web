import 'package:flutter/material.dart';
import '../services/alerta_service.dart';
import '../models/alerta_model.dart';
import 'alerta_detalle_screen.dart';

class AlertasUbicacionScreen extends StatefulWidget {
  final String ubicacion;
  const AlertasUbicacionScreen({super.key, required this.ubicacion});

  @override
  State<AlertasUbicacionScreen> createState() => _AlertasUbicacionScreenState();
}

class _AlertasUbicacionScreenState extends State<AlertasUbicacionScreen> {
  final AlertaService _alertaService = AlertaService();
  late Future<List<Alerta>> _alertasUbicacion;

  @override
  void initState() {
    super.initState();
    _alertasUbicacion = _alertaService.buscarAlertas(ubicacion: widget.ubicacion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📍 ${widget.ubicacion}'),
        backgroundColor: const Color(0xFF3366CC),
      ),
      body: FutureBuilder<List<Alerta>>(
        future: _alertasUbicacion,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('❌ Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay alertas para esta ubicación.'));
          }

          final alertas = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alertas.length,
            itemBuilder: (context, index) {
              final alerta = alertas[index];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlertaDetalleScreen(alerta: alerta, rol: 'admin'),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: _colorPorNivel(alerta.nivel), size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                alerta.tipo,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              alerta.nivel,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _colorPorNivel(alerta.nivel),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              alerta.fecha.toLocal().toString().split(' ')[0],
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                        if (alerta.temperatura != null || alerta.humedad != null || alerta.viento != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                if (alerta.temperatura != null)
                                  _iconoDato('🌡️', '${alerta.temperatura}°C'),
                                if (alerta.humedad != null)
                                  _iconoDato('💧', '${alerta.humedad}%'),
                                if (alerta.viento != null)
                                  _iconoDato('💨', '${alerta.viento} km/h'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _iconoDato(String emoji, String texto) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Text(
        '$emoji $texto',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Color _colorPorNivel(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'bajo':
        return Colors.green;
      case 'moderado':
        return Colors.orange;
      case 'alto':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
