import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import '../services/reporte_service.dart';
import 'package:csv/csv.dart';

class TablaAlertasScreen extends StatefulWidget {
  const TablaAlertasScreen({super.key});

  @override
  State<TablaAlertasScreen> createState() => _TablaAlertasScreenState();
}

class _TablaAlertasScreenState extends State<TablaAlertasScreen> {
  final ReporteService _reporteService = ReporteService();
  List<Map<String, dynamic>> _datos = [];
  List<Map<String, dynamic>> _filtrados = [];
  String _filtroTipo = 'Todos';
  bool _cargando = true;

  final List<String> tipos = ['Todos', 'Lluvia', 'Viento', 'Inundación', 'Helada', 'Manual', 'Sequía'];

  // Paleta de colores
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = const Color(0xFF64B5F6);
  final Color backgroundColor = const Color(0xFFE3F2FD);
  final Color cardColor = const Color(0xFFFFFFFF);
  final Color textColor = const Color(0xFF263238);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final data = await _reporteService.obtenerAlertasCompletas();
    setState(() {
      _datos = data;
      _filtrados = data;
      _cargando = false;
    });
  }

  void _filtrarPorTipo(String? tipo) {
    if (tipo == null) return;
    setState(() {
      _filtroTipo = tipo;
      _filtrados = tipo == 'Todos'
          ? _datos
          : _datos.where((a) => (a['tipo']?.toLowerCase() ?? '').contains(tipo.toLowerCase())).toList();
    });
  }

  void _exportarCSV() {
    final List<List<dynamic>> rows = [
      ['ID', 'Tipo', 'Nivel', 'Ubicación', 'Fecha y Hora', 'Temp', 'Humedad', 'Precipitación', 'Viento'],
      ..._filtrados.map((a) => [
            a['id'],
            a['tipo'],
            a['nivel'],
            a['ubicacion'],
            a['fecha'],
            '${a['temperatura']}°C',
            '${a['humedad']}%',
            '${a['precipitacion']} mm',
            '${a['viento']} km/h',
          ])
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final blob = html.Blob([csv]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "alertas_completas.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Color _nivelColor(String nivel) {
    final n = nivel.toLowerCase();
    if (n.contains('crítico')) return Colors.red.shade400;
    if (n.contains('alto')) return Colors.orange.shade400;
    if (n.contains('moderado')) return Colors.yellow.shade600;
    if (n.contains('bajo')) return Colors.green.shade400;
    return Colors.grey.shade300;
  }

  Color _tipoColor(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('helada')) return Colors.cyan.shade600;
    if (t.contains('sequía')) return Colors.orange.shade600;
    if (t.contains('inundación')) return Colors.indigo.shade600;
    if (t.contains('lluvia')) return Colors.blue.shade600;
    if (t.contains('viento')) return Colors.deepPurple.shade400;
    return Colors.grey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
        title: const Text("📋 Tabla Completa de Alertas", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 4,
        actions: [
          Tooltip(
            message: 'Exportar a CSV',
            child: IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: _filtrados.isEmpty ? null : _exportarCSV,
            ),
          ),
        ],
      ),
      body: _cargando
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            )
          : Column(
              children: [
                // Filtros y controles
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, color: primaryColor),
                      const SizedBox(width: 8),
                      Text("Filtrar por tipo:", 
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButton<String>(
                          value: _filtroTipo,
                          underline: const SizedBox(),
                          icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                          style: TextStyle(color: textColor),
                          items: tipos.map((tipo) {
                            return DropdownMenuItem(
                              value: tipo,
                              child: Text(tipo, style: TextStyle(color: textColor)),
                            );
                          }).toList(),
                          onChanged: _filtrarPorTipo,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "${_filtrados.length} ${_filtrados.length == 1 ? 'alerta' : 'alertas'}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Tabla de datos
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Scrollbar(
                        thumbVisibility: true,
                        interactive: true,
                        radius: const Radius.circular(10),
                        thickness: 8,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) => primaryColor.withOpacity(0.05)),
                              headingTextStyle: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              dataRowHeight: 48,
                              horizontalMargin: 16,
                              columnSpacing: 24,
                              columns: [
                                DataColumn(
                                  label: Text("ID", style: TextStyle(color: primaryColor)),
                                  numeric: true,
                                ),
                                DataColumn(label: Text("🌦️ TIPO")),
                                DataColumn(label: Text("⚠️ NIVEL")),
                                DataColumn(label: Text("📍 UBICACIÓN")),
                                DataColumn(label: Text("📅 FECHA Y HORA")),
                                DataColumn(
                                  label: Text("🌡️ TEMP"),
                                  numeric: true,
                                ),
                                DataColumn(
                                  label: Text("💧 HUMEDAD"),
                                  numeric: true,
                                ),
                                DataColumn(
                                  label: Text("☔ PRECIP"),
                                  numeric: true,
                                ),
                                DataColumn(
                                  label: Text("🌬️ VIENTO"),
                                  numeric: true,
                                ),
                              ],
                              rows: _filtrados.map((alerta) {
                                final tipo = alerta['tipo']?.toString() ?? '-';
                                final nivel = alerta['nivel']?.toString() ?? '-';
                                final fecha = alerta['fecha']?.toString() ?? '-';
                                final fechaHora = fecha.replaceFirst('T', ' ').split('.')[0];
                                final ubicacion = alerta['ubicacion']?.toString() ?? '-';

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(alerta['id']?.toString() ?? '-',
                                        style: TextStyle(color: textColor)),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          Icon(Icons.circle, 
                                            color: _tipoColor(tipo), 
                                            size: 12),
                                          const SizedBox(width: 8),
                                          Text(tipo,
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _nivelColor(nivel),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          nivel.toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Tooltip(
                                        message: ubicacion,
                                        child: Text(
                                          ubicacion.length > 20
                                              ? '${ubicacion.substring(0, 20)}...'
                                              : ubicacion,
                                          style: TextStyle(color: textColor),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(fechaHora,
                                        style: TextStyle(color: textColor)),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          Icon(Icons.thermostat,
                                              size: 16, color: Colors.red.shade600),
                                          const SizedBox(width: 4),
                                          Text('${alerta['temperatura'] ?? '-'}°C',
                                              style: TextStyle(color: textColor)),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          Icon(Icons.water_drop,
                                              size: 16, color: Colors.blue.shade600),
                                          const SizedBox(width: 4),
                                          Text('${alerta['humedad'] ?? '-'}%',
                                              style: TextStyle(color: textColor)),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          Icon(Icons.grain,
                                              size: 16, color: Colors.indigo.shade600),
                                          const SizedBox(width: 4),
                                          Text('${alerta['precipitacion'] ?? '-'} mm',
                                              style: TextStyle(color: textColor)),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          Icon(Icons.air,
                                              size: 16, color: Colors.deepPurple.shade600),
                                          const SizedBox(width: 4),
                                          Text('${alerta['viento'] ?? '-'} km/h',
                                              style: TextStyle(color: textColor)),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}