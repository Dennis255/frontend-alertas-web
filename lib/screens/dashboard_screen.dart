import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../services/reporte_service.dart';
import 'package:csv/csv.dart';
import 'dart:html' as html;
import '../services/alert_notifier_service.dart'; // Comentado en tu original
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/global_config.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _nombre = '';
  String _rol = '';
  String _ciudadSeleccionada = 'Achupallas';
  String _mapaActual = 'relieve';
  final MapController _mapController = MapController();

  Map<String, LatLng> coordenadasCiudades = {
    'Achupallas': const LatLng(-2.4031, -78.7964),
    'Cebadas': const LatLng(-2.1951, -78.7750),
    'Palmira': const LatLng(-2.2113, -78.7095),
    'Riobamba': const LatLng(-1.6636, -78.6546),
  };

  Map<String, dynamic>? clima;

  @override
  void initState() {
    super.initState();
    cargarDatos();
    cargarClima();
  }

  Future<void> cargarDatos() async {
    final nombre = await SessionService.getUserName();
    final rol = await SessionService.getUserRole();
    setState(() {
      _nombre = nombre;
      _rol = rol;
    });
  }

  Future<void> cargarClima() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${GlobalConfig.baseURL}/alertas/openweather?ciudad=$_ciudadSeleccionada')
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          clima = data;
        });
      }
    } catch (e) {
      print('Error al cargar clima: $e');
    }
  }

  // --- WIDGETS DE CONSTRUCCIÓN REFACTORIZADOS ---

  /// MEJORA: _buildGrupo ahora es una Card que agrupa los ListTiles.
  Widget _buildGrupo(String titulo, List<Widget> items) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2, // Sombra sutil
      shadowColor: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white, // Fondo blanco para la lista
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              titulo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue.shade900,
              ),
            ),
          ),
          // Usamos ListView.separated para poner divisores
          ListView.separated(
            shrinkWrap: true, // Esencial dentro de un Column
            physics:
                const NeverScrollableScrollPhysics(), // No queremos scroll anidado
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 1,
              indent: 16, // Divisor no toca los bordes
              endIndent: 16,
            ),
          ),
          const SizedBox(height: 8), // Pequeño padding inferior
        ],
      ),
    );
  }

  /// NUEVO WIDGET: Una sola Card para el selector y el clima.
  Widget _buildClimaYSelectorCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 4,
      shadowColor: Colors.blue.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Selector de Ciudad
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '📍 Selecciona la ciudad para ver datos:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              value: _ciudadSeleccionada,
              items: coordenadasCiudades.keys
                  .map((ciudad) => DropdownMenuItem<String>(
                        value: ciudad,
                        child: Text(ciudad,
                            style: TextStyle(color: Colors.blue.shade800)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _ciudadSeleccionada = value;
                    _mapController.move(coordenadasCiudades[value]!, 13);
                    cargarClima();
                  });
                }
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade100),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade100),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              dropdownColor: Colors.white,
            ),
          ),
          // 2. Divisor
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Divider(thickness: 1, height: 1),
          ),
          // 3. Información del Clima
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Padding ajustado
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌤️ Datos meteorológicos para: $_ciudadSeleccionada',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                _buildWeatherInfo(
                    '🌡️', 'Temperatura', '${clima?['temperatura'] ?? '...'}°C'),
                _buildWeatherInfo(
                    '💧', 'Humedad', '${clima?['humedad'] ?? '...'}%'),
                _buildWeatherInfo('🌧️', 'Precipitación',
                    '${clima?['precipitacion'] ?? '...'} mm'),
                _buildWeatherInfo(
                    '💨', 'Viento', '${clima?['viento'] ?? '...'} km/h'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// SIN CAMBIOS: Este widget auxiliar ya estaba bien.
  Widget _buildWeatherInfo(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: Colors.blue.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// NUEVO WIDGET: Una Card que contiene el título y el mapa.
  Widget _buildMapaCard() {
    final LatLng centro = coordenadasCiudades[_ciudadSeleccionada]!;
    return Card(
      clipBehavior: Clip.antiAlias, // Importante para redondear el mapa
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 4,
      shadowColor: Colors.blue.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Título del Mapa
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text(
              '🗺️ Mapa de $_ciudadSeleccionada (actualización cada 15 min):',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          // 2. Mapa
          SizedBox(
            height: 360,
            child: Stack(
              children: [
                // Ya no se necesita ClipRRect, la Card lo hace
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                      center: centro,
                      zoom: 13,
                      interactiveFlags: InteractiveFlag.all),
                  children: [
                    TileLayer(
                      urlTemplate: _mapaActual == 'satelite'
                          ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                          : 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.tesis.alertas',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: centro,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on,
                              color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
                // Botones flotantes (sin cambios)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'refresh',
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade800,
                        elevation: 4,
                        onPressed: cargarClima,
                        child: const Icon(Icons.refresh),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'mapToggle',
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade800,
                        elevation: 4,
                        onPressed: () {
                          setState(() {
                            _mapaActual =
                                _mapaActual == 'relieve' ? 'satelite' : 'relieve';
                          });
                        },
                        child: Icon(_mapaActual == 'relieve'
                            ? Icons.satellite
                            : Icons.terrain),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// MEJORA: _buildTile ahora es un simple ListTile.
  Widget _buildTile(String title, IconData icon, VoidCallback onTap) {
    // Ya no es un Container. El _buildGrupo es la Card.
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.blue.shade800),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.blue.shade900,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing:
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue.shade600),
      onTap: onTap,
    );
  }

  /// SIN CAMBIOS: Lógica de descarga
  Future<void> _descargarRespaldo() async {
    final reporteService = ReporteService();
    final datos = await reporteService.obtenerAlertasCompletas();

    if (datos.isNotEmpty) {
      final List<List<dynamic>> filas = [
        [
          'ID',
          'Tipo',
          'Nivel',
          'Ubicación',
          'Descripción',
          'Fecha',
          'Temperatura',
          'Humedad',
          'Precipitación',
          'Viento'
        ],
        ...datos.map((a) => [
              a['id'],
              a['tipo'],
              a['nivel'],
              a['ubicacion'],
              a['descripcion'],
              a['fecha']?.toString().split('T')[0] ?? '',
              a['temperatura'] ?? '',
              a['humedad'] ?? '',
              a['precipitacion'] ?? '',
              a['viento'] ?? ''
            ]),
      ];

      final csv = const ListToCsvConverter().convert(filas);
      final blob = html.Blob([csv]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "respaldo_alertas.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos para exportar')),
      );
    }
  }

  /// MEJORA: Contenido por rol ahora usa los nuevos _buildGrupo y _buildTile.
  /// Se ha añadido un _buildGrupo al rol 'usuario' para consistencia.
  Widget _buildRolContent() {
    if (_rol == 'admin') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGrupo('🚨 Gestión de Alertas', [
            _buildTile('Ver Alertas', Icons.warning_amber,
                () => Navigator.pushNamed(context, '/alertas')),
            _buildTile('Crear Alerta', Icons.add_alert,
                () => Navigator.pushNamed(context, '/crear-alerta')),
            _buildTile('Tabla Completa de Alertas', Icons.table_chart,
                () => Navigator.pushNamed(context, '/tabla-alertas')),
          ]),
          _buildGrupo('📈 Estadísticas y Reportes', [
            _buildTile('Gráficas de Reportes', Icons.bar_chart,
                () => Navigator.pushNamed(context, '/graficas-alertas')),
            _buildTile(
                'Evolución de alertas por tipo',
                Icons.show_chart,
                () => Navigator.pushNamed(context, '/evolucion-lineas')),
            _buildTile(
                'Uso de fuentes de datos',
                Icons.pie_chart,
                () => Navigator.pushNamed(context, '/estadisticas-fuentes')),
            _buildTile(
                'Evolución diaria por fuente',
                Icons.timeline,
                () => Navigator.pushNamed(context, '/estadisticas-evolucion')),
          ]),
          _buildGrupo('📍 Datos y Monitoreo', [
            _buildTile('Alertas por Ubicación', Icons.map,
                () => Navigator.pushNamed(context, '/reportes-ubicacion')),
            _buildTile('Datos de Monitoreo', Icons.analytics_outlined,
                () => Navigator.pushNamed(context, '/monitoreo')),
          ]),
          _buildGrupo('🛠️ Administración', [
            _buildTile('Administrar Usuarios', Icons.admin_panel_settings,
                () => Navigator.pushNamed(context, '/admin')),
            _buildTile('Gestionar Umbrales', Icons.tune,
                () => Navigator.pushNamed(context, '/umbrales')),
            _buildTile(
                'Descargar Respaldo (CSV)', Icons.download, _descargarRespaldo),
          ]),
        ],
      );
    }
    if (_rol == 'autoridad') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGrupo('🚨 Gestión de Alertas', [
            _buildTile('Ver Alertas', Icons.warning_amber,
                () => Navigator.pushNamed(context, '/alertas')),
            _buildTile('Crear Alerta', Icons.add_alert,
                () => Navigator.pushNamed(context, '/crear-alerta')),
          ]),
          _buildGrupo('📊 Visualización de Reportes', [
            _buildTile('Gráficas de Reportes', Icons.bar_chart,
                () => Navigator.pushNamed(context, '/graficas-alertas')),
            _buildTile('Ver Reportes', Icons.bar_chart,
                () => Navigator.pushNamed(context, '/reportes')),
          ]),
          _buildGrupo('📍 Datos y Ubicación', [
            _buildTile('Ubicación de Alertas', Icons.map,
                () => Navigator.pushNamed(context, '/reportes-ubicacion')),
            _buildTile('Datos de Monitoreo', Icons.analytics_outlined,
                () => Navigator.pushNamed(context, '/monitoreo')),
          ]),
          _buildGrupo('📈 Fuentes y Configuración', [
            _buildTile(
                'Uso de fuentes de datos',
                Icons.pie_chart,
                () => Navigator.pushNamed(context, '/estadisticas-fuentes')),
            _buildTile(
                'Evolución diaria por fuente',
                Icons.timeline,
                () => Navigator.pushNamed(context, '/estadisticas-evolucion')),
            _buildTile('Gestionar Umbrales', Icons.tune,
                () => Navigator.pushNamed(context, '/umbrales')),
          ]),
        ],
      );
    } else if (_rol == 'usuario') {
      // MEJORA: Añadido _buildGrupo para consistencia visual
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGrupo('🚀 Acciones', [
            _buildTile('Ver Alertas', Icons.warning_amber,
                () => Navigator.pushNamed(context, '/alertas')),
            _buildTile('Historial de Alertas', Icons.history,
                () => Navigator.pushNamed(context, '/tabla-alertas')),
            _buildTile('Alertas por Ubicación', Icons.place_outlined,
                () => Navigator.pushNamed(context, '/alertas-ubicacion')),
            _buildTile('Gráficas de Reportes', Icons.bar_chart,
                () => Navigator.pushNamed(context, '/graficas-alertas')),
          ]),
        ],
      );
    } else if (_rol == 'invitado') {
      // El rol de invitado tiene su propio estilo de tarjeta, se respeta
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.lightBlue.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade100,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade800),
                  const SizedBox(width: 8),
                  Text(
                    'Información para Invitados',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '⚠️ Alerta actual: Lluvia leve en la región\n'
                'Regístrate para recibir recomendaciones personalizadas.',
                style: TextStyle(color: Colors.blue.shade700),
              ),
            ],
          ),
        ),
      );
    } else {
      return Center(
        child: Text(
          'Rol no reconocido.',
          style: TextStyle(color: Colors.blue.shade800),
        ),
      );
    }
  }

  /// --- MÉTODO BUILD PRINCIPAL (MODIFICADO) ---
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //AlertNotifierService().setContext(context);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Principal'),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.lightBlue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          // ============= LOGOS DE HEADER AÑADIDOS AQUÍ =============
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5), // Ajusta la altura
            child: Row(
              children: [
                Image.asset(
                  'assets/UNACH.png',
                  errorBuilder: (c, e, s) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 15),
                Image.asset(
                  'assets/TI.png',
                  errorBuilder: (c, e, s) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 15), // Espacio antes del icono de perfil
              ],
            ),
          ),
          // ============= FIN DE LOGOS DE HEADER =============

          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.pushNamed(context, '/perfil'),
          ),
        ],
      ),
      // MEJORA: Fondo base del Scaffold
      backgroundColor: Colors.blue.shade50,
      body: SingleChildScrollView(
        // Ya no necesita padding, los márgenes de las Cards lo manejan
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cabecera de Bienvenida (se mantiene igual, es un buen header)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.lightBlue.shade200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Bienvenid@, $_nombre',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ),

            // 2. NUEVA TARJETA: Clima y Selector
            _buildClimaYSelectorCard(),

            // 3. NUEVA TARJETA: Mapa
            _buildMapaCard(),

            // 4. Contenido por Rol (ahora usa las Cards)
            const SizedBox(height: 8),
            _buildRolContent(),

            // ============= LOGO DE FOOTER AÑADIDO AQUÍ =============
            const SizedBox(height: 24), // Espacio antes del footer
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.grey[200], // Fondo para separar visualmente
              width: double.infinity,
              child: Image.asset(
                'assets/SEAP.png',
                fit: BoxFit.fitWidth,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              ),
            ),
            // ============= FIN DE LOGO DE FOOTER =============
          ],
        ),
      ),
    );
  }
}