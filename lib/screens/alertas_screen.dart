import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/alerta_service.dart';
import '../models/alerta_model.dart';
import 'alerta_detalle_screen.dart';
import '../services/alert_notifier_service.dart';
import 'package:intl/intl.dart';

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  final AlertaService _alertaService = AlertaService();
  List<Alerta> _todas = [];
  List<Alerta> _filtradas = [];
  String _tipoSeleccionado = 'Todos';
  String _rangoFecha = 'Todos';
  late Timer _timer;

  final List<String> _rangoFechas = [
    'Todos',
    'Hoy',
    'Últimos 7 días',
    'Últimos 30 días',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _iniciarActualizacion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AlertNotifierService().iniciarVerificacionPeriodica();
    });
  }

  void _iniciarActualizacion() {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _cargarDatos());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      final alertas = await _alertaService.fetchAlertas();
      alertas.sort((a, b) => b.fecha.compareTo(a.fecha));
      setState(() {
        _todas = alertas;
        _aplicarFiltro();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar alertas: ${e.toString()}'),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  String _normalizarTipo(String tipo) {
    final tipoLower = tipo.toLowerCase();
    if (tipoLower.contains('helada')) return 'Helada';
    if (tipoLower.contains('sequía')) return 'Sequía';
    if (tipoLower.contains('inund')) return 'Inundación';
    if (tipoLower.contains('lluvia')) return 'Lluvia';
    if (tipoLower.contains('viento')) return 'Viento';
    if (tipoLower.contains('tormenta')) return 'Tormenta';
    if (tipoLower.contains('granizo')) return 'Granizo';
    return 'Otro';
  }

  void _aplicarFiltro() {
    setState(() {
      _filtradas =
          _todas.where((alerta) {
            final tipoFiltrado = _normalizarTipo(alerta.tipo);
            final tipoOk =
                _tipoSeleccionado == 'Todos' ||
                tipoFiltrado == _tipoSeleccionado;

            final ahora = DateTime.now();
            final fecha = alerta.fecha;
            bool fechaOk = true;

            if (_rangoFecha == 'Hoy') {
              final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
              final finHoy = inicioHoy
                  .add(const Duration(days: 1))
                  .subtract(const Duration(milliseconds: 1));
              fechaOk = fecha.isAfter(inicioHoy) && fecha.isBefore(finHoy);
            } else if (_rangoFecha == 'Últimos 7 días') {
              fechaOk = fecha.isAfter(ahora.subtract(const Duration(days: 7)));
            } else if (_rangoFecha == 'Últimos 30 días') {
              fechaOk = fecha.isAfter(ahora.subtract(const Duration(days: 30)));
            }

            return tipoOk && fechaOk;
          }).toList();
    });
  }

  String _iconoTipo(String tipo) {
    final tipoLower = tipo.toLowerCase();
    if (tipoLower.contains('lluvia')) return '🌧️';
    if (tipoLower.contains('helada')) return '❄️';
    if (tipoLower.contains('viento')) return '🌬️';
    if (tipoLower.contains('sequía')) return '💧';
    if (tipoLower.contains('inundación')) return '🌊';
    if (tipoLower.contains('tormenta')) return '⚡';
    if (tipoLower.contains('granizo')) return '🧊';
    return '⚠️';
  }

  Color _colorTipo(String tipo) {
    final tipoLower = tipo.toLowerCase();
    if (tipoLower.contains('helada')) return const Color(0xFFE6F3FF);
    if (tipoLower.contains('sequía')) return const Color(0xFFFFF2E6);
    if (tipoLower.contains('inundación')) return const Color(0xFFE6F9FF);
    if (tipoLower.contains('lluvia')) return const Color(0xFFE6F0FF);
    if (tipoLower.contains('tormenta')) return const Color(0xFFE6E6FF);
    if (tipoLower.contains('granizo')) return const Color(0xFFF0F0FF);
    return const Color(0xFFF5F5F5);
  }

  Color _colorNivel(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'extremo':
        return Colors.red[700]!;
      case 'alto':
        return Colors.orange[700]!;
      case 'medio':
        return Colors.yellow[700]!;
      case 'bajo':
        return Colors.green[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  bool _coordValidas(String ubicacion) {
    final partes = ubicacion.split(',');
    return partes.length == 2 &&
        double.tryParse(partes[0]) != null &&
        double.tryParse(partes[1]) != null;
  }

  Widget _miniMapa(String ubicacion) {
    final partes = ubicacion.split(',');
    final lat = double.parse(partes[0]);
    final lng = double.parse(partes[1]);
    final punto = LatLng(lat, lng);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 160,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FlutterMap(
            options: MapOptions(
              center: punto,
              zoom: 13,
              interactiveFlags:
                  InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
                userAgentPackageName: 'com.tesis.alertas',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: punto,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    final tiposUnicos =
        _todas.map((a) => _normalizarTipo(a.tipo)).toSet().toList();
    tiposUnicos.sort();
    final tiposDropdown = ['Todos', ...tiposUnicos];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue[100]!,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar Alertas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3366CC),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _tipoSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Alerta',
                    labelStyle: const TextStyle(color: Color(0xFF3366CC)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF3366CC)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items:
                      tiposDropdown
                          .map(
                            (t) => DropdownMenuItem<String>(
                              value: t,
                              child: Text(
                                t,
                                style: const TextStyle(
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (String? val) {
                    if (val != null) {
                      setState(() {
                        _tipoSeleccionado = val;
                        _aplicarFiltro();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _rangoFecha,
                  decoration: InputDecoration(
                    labelText: 'Rango de Fechas',
                    labelStyle: const TextStyle(color: Color(0xFF3366CC)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF3366CC)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items:
                      _rangoFechas
                          .map(
                            (f) => DropdownMenuItem<String>(
                              value: f,
                              child: Text(
                                f,
                                style: const TextStyle(
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (String? val) {
                    if (val != null) {
                      setState(() {
                        _rangoFecha = val;
                        _aplicarFiltro();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mostrando ${_filtradas.length} de ${_todas.length} alertas',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF3366CC),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Alertas Climáticas',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Última actualización: ${DateTime.now().toString().substring(0, 16)}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Actualizar ahora',
                onPressed: _cargarDatos,
              ),
              IconButton(
                icon: const Icon(Icons.home, color: Colors.white),
                tooltip: 'Ir al Dashboard',
                onPressed:
                    () => Navigator.pushReplacementNamed(context, '/dashboard'),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                tooltip: 'Información',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Información'),
                          content: const Text(
                            'Este panel muestra alertas climáticas en tiempo real. '
                            'Puedes filtrar por tipo y rango de fechas. '
                            'Las alertas se actualizan automáticamente cada 30 segundos.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Entendido'),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6E4FF)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Color(0xFF3366CC)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: Column(
        children: [
          _buildHeader(),
          _buildFiltros(),
          Expanded(
            child:
                _filtradas.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            size: 48,
                            color: Color(0xFF3366CC),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay alertas para los filtros seleccionados',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _tipoSeleccionado = 'Todos';
                                _rangoFecha = 'Todos';
                                _aplicarFiltro();
                              });
                            },
                            child: const Text(
                              'Mostrar todas las alertas',
                              style: TextStyle(color: Color(0xFF3366CC)),
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _filtradas.length,
                      itemBuilder: (_, index) {
                        final alerta = _filtradas[index];
                        //final fechaHora = alerta.fecha.toLocal().toString().split('.')[0];
                        /*final fechaFormateada = DateFormat(
                          'yyyy-MM-dd HH:mm',
                        ).format(alerta.fecha.toLocal());
*/
                        final fechaFormateada = DateFormat(
                          'yyyy-MM-dd HH:mm',
                        ).format(alerta.fecha.toLocal());

                        final diasDiferencia =
                            DateTime.now().difference(alerta.fecha).inDays;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: _colorTipo(alerta.tipo),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => AlertaDetalleScreen(
                                        alerta: alerta,
                                        rol: "admin",
                                      ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "${_iconoTipo(alerta.tipo)} ${alerta.tipo}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Color(0xFF333333),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _colorNivel(alerta.nivel),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              alerta.nivel.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: Color(0xFF666666),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            fechaFormateada,
                                            style: const TextStyle(
                                              color: Color(0xFF666666),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: Color(0xFF666666),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            diasDiferencia == 0
                                                ? 'Hoy'
                                                : 'Hace $diasDiferencia día${diasDiferencia == 1 ? '' : 's'}',
                                            style: const TextStyle(
                                              color: Color(0xFF666666),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        alerta.descripcion,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF444444),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          if (alerta.temperatura != null)
                                            _buildInfoChip(
                                              '🌡️ ${alerta.temperatura}°C',
                                            ),
                                          if (alerta.humedad != null)
                                            _buildInfoChip(
                                              '💧 ${alerta.humedad}% humedad',
                                            ),
                                          if (alerta.precipitacion != null)
                                            _buildInfoChip(
                                              '☔ ${alerta.precipitacion} mm',
                                            ),
                                          if (alerta.viento != null)
                                            _buildInfoChip(
                                              '🌬️ ${alerta.viento} km/h',
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (_coordValidas(alerta.ubicacion))
                                  _miniMapa(alerta.ubicacion),
                                Padding(
                                  padding: const EdgeInsets.all(
                                    16,
                                  ).copyWith(top: 0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '📍 ${alerta.ubicacion}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF666666),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Text(
                                        'Ver detalles →',
                                        style: TextStyle(
                                          color: Color(0xFF3366CC),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
