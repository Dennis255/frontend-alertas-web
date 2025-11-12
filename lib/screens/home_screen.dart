import 'package:flutter/material.dart';
import '../models/alerta_model.dart';
import '../services/alerta_service.dart';
import '../services/session_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AlertaService _alertaService = AlertaService();
  List<Alerta> _alertas = [];
  String _rol = '';
  String _nombre = '';
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final rol = await SessionService.getUserRole();
    final nombre = await SessionService.getUserName();
    final datos = await _alertaService.fetchAlertas();
    setState(() {
      _rol = rol;
      _nombre = nombre;
      _alertas = datos;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
              ),
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE3F2FD),
                    Color(0xFFBBDEFB),
                    Color(0xFF90CAF9),
                  ],
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 32, color: Color(0xFF1976D2)),
                        const SizedBox(width: 16),
                        Text(
                          'Bienvenido $_nombre 👋',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_rol == 'invitado') ...[
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: const Color(0xFFE3F2FD),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Color(0xFF1976D2), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '🔒 Estás en modo invitado. Regístrate para más funciones.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.notifications_active,
                            color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Últimas Alertas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._alertas.map((a) => Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                const Color(0xFFE3F2FD).withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Icon(
                              _getIconForAlertType(a.tipo),
                              color: _getColorForAlertLevel(a.nivel),
                              size: 32,
                            ),
                            title: Text(
                              a.tipo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D47A1),
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow(
                                      'Nivel:', a.nivel, Icons.warning),
                                  _buildDetailRow(
                                      'Ubicación:', a.ubicacion, Icons.location_on),
                                  _buildDetailRow(
                                      'Fecha:',
                                      a.fecha.toLocal().toString().split(' ')[0],
                                      Icons.calendar_today),
                                  if (_rol != 'invitado') ...[
                                    _buildDetailRow('Temp:',
                                        '${a.temperatura} °C', Icons.thermostat),
                                    _buildDetailRow('Humedad:',
                                        '${a.humedad} %', Icons.water_drop),
                                    _buildDetailRow('Precipitación:',
                                        '${a.precipitacion} mm', Icons.cloudy_snowing),
                                    _buildDetailRow('Viento:',
                                        '${a.viento} km/h', Icons.air),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue[600]),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.blue[900],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForAlertType(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'tormenta':
        return Icons.thunderstorm;
      case 'inundación':
        return Icons.flood;
      case 'incendio':
        return Icons.local_fire_department;
      case 'terremoto':
        return Icons.terrain;
      default:
        return Icons.warning;
    }
  }

  Color _getColorForAlertLevel(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'alto':
        return Colors.red;
      case 'medio':
        return Colors.orange;
      case 'bajo':
        return Colors.yellow[700]!;
      default:
        return Colors.blue;
    }
  }
}