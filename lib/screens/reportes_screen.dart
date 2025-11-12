import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'dart:html' as html;
import 'dart:math';
import '../services/reporte_service.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});
  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final ReporteService _reporteService = ReporteService();
  List<Map<String, dynamic>> _datos = [];
  Set<String> _categoriasSeleccionadas = {'Helada', 'Sequía', 'Lluvia'};
  bool _isLoading = true;

  final Map<String, Color> colorPorTipo = {
    'Lluvia': Colors.blue.shade700,
    'Helada': Colors.cyan.shade600,
    'Sequía': Colors.orange.shade600,
    'Viento': Colors.purple.shade600,
    'Inundación': Colors.indigo.shade600,
    'Manual': Colors.grey.shade600,
    'Alto': Colors.red.shade600,
    'Moderado': Colors.orange.shade400,
    'Bajo': Colors.green.shade600,
    'Otro': Colors.grey.shade400,
  };

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final data = await _reporteService.obtenerResumenAlertas();
      setState(() => _datos = data);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, int> _agruparPorTipoSimplificado() {
    final Map<String, int> resumen = {};
    for (var item in _datos) {
      final tipoOriginal = item['tipo']?.toString().toLowerCase() ?? '';
      final cantidad = int.tryParse(item['cantidad'].toString()) ?? 0;
      String tipoGeneral = 'Otro';
      if (tipoOriginal.contains('helada')) tipoGeneral = 'Helada';
      else if (tipoOriginal.contains('sequía')) tipoGeneral = 'Sequía';
      else if (tipoOriginal.contains('lluvia')) tipoGeneral = 'Lluvia';
      else if (tipoOriginal.contains('viento')) tipoGeneral = 'Viento';
      else if (tipoOriginal.contains('inund')) tipoGeneral = 'Inundación';
      else if (tipoOriginal.contains('manual')) tipoGeneral = 'Manual';

      if (_categoriasSeleccionadas.contains(tipoGeneral)) {
        resumen[tipoGeneral] = (resumen[tipoGeneral] ?? 0) + cantidad;
      }
    }
    return resumen;
  }

  Map<String, int> _agruparPorNivel() {
    final Map<String, int> resumen = {};
    for (var item in _datos) {
      String nivel = item['nivel']?.toString().toLowerCase() ?? 'desconocido';
      final cantidad = int.tryParse(item['cantidad'].toString()) ?? 0;
      if (nivel.contains('moderado') || nivel.contains('medio')) nivel = 'Moderado';
      else if (nivel.contains('alto')) nivel = 'Alto';
      else if (nivel.contains('bajo')) nivel = 'Bajo';
      else nivel = 'Otro';
      resumen[nivel] = (resumen[nivel] ?? 0) + cantidad;
    }
    return resumen;
  }

  Widget _buildFiltros() {
    final tipos = {
      ..._datos.map((e) {
        final tipo = e['tipo']?.toString().toLowerCase() ?? '';
        if (tipo.contains('helada')) return 'Helada';
        if (tipo.contains('sequía')) return 'Sequía';
        if (tipo.contains('lluvia')) return 'Lluvia';
        if (tipo.contains('viento')) return 'Viento';
        if (tipo.contains('inund')) return 'Inundación';
        if (tipo.contains('manual')) return 'Manual';
        return 'Otro';
      })
    }.toList();

    tipos.sort((a, b) {
      const prioridad = ['Helada', 'Sequía', 'Lluvia'];
      int indexA = prioridad.contains(a) ? prioridad.indexOf(a) : 99;
      int indexB = prioridad.contains(b) ? prioridad.indexOf(b) : 99;
      return indexA.compareTo(indexB);
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrar por tipo de alerta:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tipos.map((tipo) {
                final seleccionado = _categoriasSeleccionadas.contains(tipo);
                return FilterChip(
                  label: Text(tipo),
                  labelStyle: TextStyle(
                    color: seleccionado ? Colors.white : Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  selected: seleccionado,
                  selectedColor: colorPorTipo[tipo] ?? Colors.blueGrey,
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) _categoriasSeleccionadas.add(tipo);
                      else _categoriasSeleccionadas.remove(tipo);
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data) {
    if (data.isEmpty) {
      return Card(
        elevation: 3,
        margin: const EdgeInsets.only(top: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text("No hay datos disponibles para los filtros seleccionados.",
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    
    final entries = data.entries.toList();
    final ancho = max(entries.length * 80.0, MediaQuery.of(context).size.width);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(top: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Distribución por Tipo de Alerta",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text("Total alertas: ${data.values.fold(0, (sum, value) => sum + value)}",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 16),
            SizedBox(
              width: ancho,
              height: 300,
              child: BarChart(
                BarChartData(
                  barGroups: List.generate(entries.length, (i) {
                    final tipo = entries[i].key;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: entries[i].value.toDouble(),
                          width: 28,
                          color: colorPorTipo[tipo] ?? Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        )
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i >= entries.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(entries[i].key,
                                style: const TextStyle(fontSize: 12)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString(),
                              style: const TextStyle(fontSize: 12));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> data) {
    if (data.isEmpty) {
      return Card(
        elevation: 3,
        margin: const EdgeInsets.only(top: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text("No hay datos disponibles para mostrar.",
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    
    final total = data.values.fold(0, (s, v) => s + v);
    final entries = data.entries.toList();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(top: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Distribución por Nivel de Riesgo",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text("Total alertas: $total",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: List.generate(entries.length, (i) {
                          final pct = (entries[i].value / total) * 100;
                          return PieChartSectionData(
                            value: entries[i].value.toDouble(),
                            title: '${pct.toStringAsFixed(1)}%',
                            color: colorPorTipo[entries[i].key] ?? Colors.grey,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            radius: 80,
                            badgePositionPercentageOffset: 0.8,
                          );
                        }),
                        sectionsSpace: 0,
                        centerSpaceRadius: 50,
                        startDegreeOffset: -90,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colorPorTipo[entry.key],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${entry.key} (${entry.value})',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
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
    final tipoData = _agruparPorTipoSimplificado();
    final nivelData = _agruparPorNivel();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Reportes de Alertas'),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar datos',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Text('Exportar a CSV'),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Text('Exportar a PDF'),
              ),
            ],
            onSelected: (value) {
              if (value == 'csv') _exportarCSV();
              if (value == 'pdf') _exportarPDF();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Análisis de Alertas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              )),
                          const SizedBox(height: 8),
                          Text(
                            'Visualización estadística de las alertas registradas en el sistema. Los datos se alinean con el ODS 13: Acción por el Clima.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFiltros(),
                  _buildBarChart(tipoData),
                  _buildPieChart(nivelData),
                ],
              ),
            ),
    );
  }

  void _exportarCSV() {
    final rows = [
      ['Tipo', 'Nivel', 'Cantidad'],
      ..._datos.map((e) => [e['tipo'], e['nivel'], e['cantidad']]),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final blob = html.Blob([csv]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "reporte_alertas_${DateTime.now().toIso8601String()}.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }
  


void _exportarPDF() async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Reporte de Alertas',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              )),
          pw.SizedBox(height: 8),
          pw.Text('Generado el: ${DateTime.now().toString()}',
              style: pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['Tipo', 'Nivel', 'Cantidad'],
            data: _datos.map((e) => [e['tipo'], e['nivel'], e['cantidad'].toString()]).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: pw.BoxDecoration(
              color: _createPdfColor(30, 58, 138), // Azul oscuro (#1E3A8A)
            ),
            cellPadding: pw.EdgeInsets.all(4),
            border: pw.TableBorder.all(
              color: _createPdfColor(229, 231, 235), // Gris claro (#E5E7EB)
              width: 0.5,
            ),
          ),
        ],
      ),
    ),
  );
  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}

// Función compatible con pdf 3.10.4
dynamic _createPdfColor(int r, int g, int b) {
  return PdfColor.fromInt((0xFF << 24) | (r << 16) | (g << 8) | b);
}
}