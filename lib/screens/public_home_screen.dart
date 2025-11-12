import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../config/global_config.dart';

class PublicHomeScreen extends StatefulWidget {
  const PublicHomeScreen({Key? key}) : super(key: key);

  @override
  _PublicHomeScreenState createState() => _PublicHomeScreenState();
}

class _PublicHomeScreenState extends State<PublicHomeScreen> {
  List<dynamic> alertas = [];
  int totalAnterior = 0;
  bool isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;
  String _mapaActual = 'relieve';
  Map<String, dynamic>? clima;
  bool _cargandoClima = false;

  final LatLng centro = const LatLng(-2.4844, -78.8451);

  @override
  void initState() {
    super.initState();
    obtenerAlertas();
    cargarClima();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => verificarNuevasAlertas());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> obtenerAlertas() async {
    final url = Uri.parse('${GlobalConfig.baseURL}/api/alertas');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final datos = jsonDecode(response.body);
        setState(() {
          alertas = datos;
          totalAnterior = datos.length;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error al obtener alertas iniciales: $e');
    }
  }

  Future<void> verificarNuevasAlertas() async {
    try {
      final response = await http.get(Uri.parse('${GlobalConfig.baseURL}/api/alertas'));
      if (response.statusCode == 200) {
        final nuevas = jsonDecode(response.body);
        if (nuevas.length > totalAnterior) {
          _reproducirSonido();
          _cambiarTituloPestana();
        }
        setState(() {
          alertas = nuevas;
          totalAnterior = nuevas.length;
        });
      }
    } catch (e) {
      print('Error al verificar nuevas alertas: $e');
    }
  }

  void _cambiarTituloPestana() {
    html.document.title = '🚨 ¡Nueva alerta detectada!';
    Future.delayed(const Duration(seconds: 5), () {
      html.document.title = '🌤️ Sistema de Alertas Tempranas';
    });
  }

  Future<void> _reproducirSonido() async {
    await _audioPlayer.play(AssetSource('assets/sounds/alert.mp3'));
  }

  Future<void> cargarClima() async {
    setState(() => _cargandoClima = true);
    try {
      final response = await http.get(Uri.parse('${GlobalConfig.baseURL}/api/openweather'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          clima = data;
        });
      }
    } catch (e) {
      print('Error al cargar clima: $e');
    } finally {
      setState(() => _cargandoClima = false);
    }
  }

  Color _getNivelColor(String nivel) {
    switch (nivel.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/login'),
        label: const Text('Iniciar sesión', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.login, size: 24),
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    
                    // Encabezado
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.blue.shade700, Colors.lightBlue.shade400],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade800.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      // ================== MODIFICACIÓN AQUÍ ==================
                      child: Row( // Se cambió a Row para alinear texto y logos
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Columna de Texto (Izquierda)
                          Expanded( // Para que el texto ocupe el espacio disponible
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('🌤️ Sistema de Alertas Tempranas',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    )),
                                const SizedBox(height: 8),
                                Text('Visualización pública de alertas activas en Achupallas',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                    )),
                              ],
                            ),
                          ),
                          //------INicio logos superior 
                          const SizedBox(width: 20), // Espacio entre texto y logos

                          // Logos (Derecha) - NUEVO
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/UNACH.png', // <-- RUTA DEL LOGO
                                height: 80, // Altura del logo
    
                              ),
                              const SizedBox(width: 12), // Espacio entre logos
                              Image.asset(
                                'assets/TI.png', // <-- RUTA DEL LOGO
                                height: 100, // Altura del logo
                              ),
                            ],
                          ),
                        ],
                      ),
                      // ================ FIN DE LA MODIFICACIÓN ================
                    ),

                    // Mapa
                    Card(
                      margin: const EdgeInsets.all(16),
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 360,
                          child: Stack(
                            children: [
                              FlutterMap(
                                options: MapOptions(center: centro, zoom: 13),
                                children: [
                                  TileLayer(
                                    urlTemplate: _mapaActual == 'satelite'
                                        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                                        : 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                                    subdomains: _mapaActual == 'satelite' ? [] : ['a', 'b', 'c'],
                                    userAgentPackageName: 'com.tesis.alertas',
                                  ),
                                  MarkerLayer(
                                    markers: alertas.map((alerta) {
                                      return Marker(
                                        point: LatLng(
                                          double.tryParse(alerta['lat'].toString()) ?? centro.latitude,
                                          double.tryParse(alerta['lng'].toString()) ?? centro.longitude,
                                        ),
                                        width: 40,
                                        height: 40,
                                        child: Icon(
                                          Icons.warning_rounded,
                                          size: 32,
                                          color: _getNivelColor(alerta['nivel'] ?? ''),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),

                              // Widget de clima
                              if (clima != null)
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.thermostat, size: 18, color: Colors.blue),
                                            const SizedBox(width: 4),
                                            Text('${clima!['temperatura']}°C',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                )),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.water_drop, size: 16, color: Colors.blue),
                                            const SizedBox(width: 4),
                                            Text('${clima!['humedad']}% humedad',
                                                style: const TextStyle(fontSize: 14)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.air, size: 16, color: Colors.blue),
                                            const SizedBox(width: 4),
                                            Text('${clima!['viento']} km/h viento',
                                                style: const TextStyle(fontSize: 14)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Botones de control
                              Positioned(
                                bottom: 16,
                                left: 16,
                                child: Row(
                                  children: [
                                    FloatingActionButton.small(
                                      heroTag: 'refresh',
                                      onPressed: _cargandoClima ? null : cargarClima,
                                      backgroundColor: Colors.white,
                                      child: _cargandoClima
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Icon(Icons.refresh, color: Colors.blue),
                                    ),
                                    const SizedBox(width: 8),
                                    FloatingActionButton.small(
                                      heroTag: 'map',
                                      onPressed: () {
                                        setState(() {
                                          _mapaActual = _mapaActual == 'relieve' ? 'satelite' : 'relieve';
                                        });
                                      },
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        _mapaActual == 'relieve' ? Icons.satellite : Icons.terrain,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Lista de alertas
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Alertas Activas',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: alertas.length,
                              itemBuilder: (context, index) {
                                final alerta = alertas[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/public-alerta-detalle',
                                      arguments: alerta,
                                    );
                                  },
                                  child: Container(
                                    width: 220,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      color: _getNivelColor(alerta['nivel'] ?? '').withOpacity(0.1),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.warning_rounded,
                                                  color: _getNivelColor(alerta['nivel'] ?? ''),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    alerta['tipo'].toString().toUpperCase(),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Nivel: ${alerta['nivel']}',
                                              style: TextStyle(
                                                color: _getNivelColor(alerta['nivel'] ?? ''),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '📍 ${alerta['ubicacion']}',
                                              style: const TextStyle(fontSize: 14),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '📅 ${alerta['fecha'].toString().substring(0, 10)}',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            const Spacer(),
                                            Align(
                                              alignment: Alignment.bottomRight,
                                              child: Text(
                                                "Ver detalles →",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ================== NUEVO FOOTER ==================
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: Colors.grey[200],
                      width: double.infinity,
                      child: Center(
                        child: Image.asset(
                          'assets/SEAP.png', 
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                    // ================ FIN DEL FOOTER ================
                  ],
                ),
              ),
      ),
    );
  }
}