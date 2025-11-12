import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../config/global_config.dart';

class EstadisticasEvolucionScreen extends StatefulWidget {
  const EstadisticasEvolucionScreen({super.key});

  @override
  State<EstadisticasEvolucionScreen> createState() => _EstadisticasEvolucionScreenState();
}

class _EstadisticasEvolucionScreenState extends State<EstadisticasEvolucionScreen> {
  List<String> dias = [];
  Map<String, Map<String, int>> datosPorFuente = {};
  bool _isLoading = true;
  bool _hasError = false;
  String? _fuenteSeleccionada;
  final List<Color> colores = [
    const Color(0xFF4285F4),
    const Color(0xFFEA4335),
    const Color(0xFFFBBC05),
    const Color(0xFF34A853),
    const Color(0xFF673AB7),
    const Color(0xFFFF5722),
    const Color(0xFF009688),
    const Color(0xFFE91E63),
  ];

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final url = Uri.parse('${GlobalConfig.baseURL}/api/monitoreo/estadisticas/fuentes/diario');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final List decoded = jsonDecode(res.body);

        final diasSet = <String>{};
        final fuentesMap = <String, Map<String, int>>{};

        for (var d in decoded) {
          final dia = d['dia'];
          final fuente = d['fuente'] ?? 'desconocida';
          final cantidad = int.tryParse(d['cantidad'].toString()) ?? 0;

          diasSet.add(dia);
          fuentesMap.putIfAbsent(fuente, () => {});
          fuentesMap[fuente]![dia] = cantidad;
        }

        final sortedDias = diasSet.toList()..sort();

        setState(() {
          dias = sortedDias;
          datosPorFuente = fuentesMap;
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar datos: ${res.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> exportarCSV() async {
    final encabezado = ['Día', ...datosPorFuente.keys];
    final filas = [encabezado];

    for (var dia in dias) {
      final fila = [dia];
      for (var fuente in datosPorFuente.keys) {
        fila.add((datosPorFuente[fuente]?[dia] ?? 0).toString());
      }
      filas.add(fila);
    }

    final csv = const ListToCsvConverter().convert(filas);
    final blob = html.Blob([csv]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "evolucion_fuentes_${DateTime.now().toIso8601String()}.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> exportarPDF() async {
    final pdf = pw.Document();
    final headers = ['Día', ...datosPorFuente.keys];
    final data = dias.map((dia) {
      final fila = [dia];
      for (var fuente in datosPorFuente.keys) {
        fila.add(datosPorFuente[fuente]?[dia]?.toString() ?? '0');
      }
      return fila;
    }).toList();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Evolución Diaria por Fuente',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Generado el ${DateTime.now().toString().substring(0, 10)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: headers,
              data: data,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue700,
              ),
              cellAlignment: pw.Alignment.center,
              cellPadding: const pw.EdgeInsets.all(6),
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 1,
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _exportarFuenteCSV(String fuente) async {
    final datosFuente = datosPorFuente[fuente]!;
    final csvData = [
      ['Día', 'Cantidad'],
      ...dias.map((dia) => [dia, datosFuente[dia] ?? 0]).toList(),
      ['Total', datosFuente.values.fold(0, (a, b) => a + b)]
    ];

    final csv = const ListToCsvConverter().convert(csvData);
    final blob = html.Blob([csv]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "evolucion_${fuente.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().toIso8601String()}.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _exportarFuentePDF(String fuente) async {
    final datosFuente = datosPorFuente[fuente]!;
    final total = datosFuente.values.fold(0, (a, b) => a + b);
    final maxValue = datosFuente.values.reduce((a, b) => a > b ? a : b);
    final maxDia = datosFuente.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Evolución de $fuente',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Generado el ${DateTime.now().toString().substring(0, 10)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Día', 'Cantidad'],
                data: dias.map((dia) => [dia, datosFuente[dia]?.toString() ?? '0']).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue700,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(6),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Resumen Estadístico',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Total registros: $total'),
              pw.Text('Día con más registros: $maxDia ($maxValue)'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Widget _buildSelectorFuentes() {
    return Column(
      children: [
        Text('Ver evolución individual:',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700)),
        SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: datosPorFuente.keys.map((fuente) {
              final index = datosPorFuente.keys.toList().indexOf(fuente);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(fuente),
                  selected: _fuenteSeleccionada == fuente,
                  onSelected: (selected) {
                    setState(() {
                      _fuenteSeleccionada = selected ? fuente : null;
                    });
                  },
                  selectedColor: colores[index % colores.length],
                  labelStyle: TextStyle(
                    color: _fuenteSeleccionada == fuente
                        ? Colors.white
                        : Colors.grey.shade800,
                  ),
                  avatar: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colores[index % colores.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGraficaIndividual(String fuente) {
    final datosFuente = datosPorFuente[fuente]!;
    final maxValue = datosFuente.values.reduce((a, b) => a > b ? a : b);
    final index = datosPorFuente.keys.toList().indexOf(fuente);

    return Card(
      margin: EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.timeline, color: colores[index % colores.length]),
                    SizedBox(width: 8),
                    Text('Evolución de $fuente',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colores[index % colores.length],
                        )),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.picture_as_pdf, size: 20),
                      onPressed: () => _exportarFuentePDF(fuente),
                      tooltip: 'Exportar a PDF',
                    ),
                    IconButton(
                      icon: Icon(Icons.insert_drive_file, size: 20),
                      onPressed: () => _exportarFuenteCSV(fuente),
                      tooltip: 'Exportar a CSV',
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < dias.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                dias[index].substring(5),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            );
                          }
                          return SizedBox.shrink();
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: max(1, (maxValue / 5).ceilToDouble()),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: dias.length.toDouble() - 1,
                  minY: 0,
                  maxY: maxValue * 1.2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: dias.asMap().entries.map((entry) {
                        final index = entry.key;
                        final dia = entry.value;
                        return FlSpot(
                          index.toDouble(),
                          datosFuente[dia]?.toDouble() ?? 0,
                        );
                      }).toList(),
                      isCurved: true,
                      color: colores[index % colores.length],
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colores[index % colores.length].withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evolución Diaria por Fuente'),
        backgroundColor: const Color(0xFF3366CC),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: exportarPDF,
            tooltip: 'Exportar a PDF',
          ),
          IconButton(
            icon: const Icon(Icons.insert_drive_file),
            onPressed: exportarCSV,
            tooltip: 'Exportar a CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cargarDatos,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      //body
      body: Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFF5F9FF),
        Colors.white,
      ],
    ),
  ),
  padding: const EdgeInsets.all(16),
  child: _isLoading
      ? const Center(child: CircularProgressIndicator())
      : _hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 20),
                  const Text(
                    'Error al cargar los datos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: cargarDatos,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Distribución por Fuente',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3366CC),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 300,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceBetween,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    tooltipBgColor: Colors.white,
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      final fuente = datosPorFuente.keys.toList()[rodIndex];
                                      final dia = dias[group.x.toInt()];
                                      final valor = datosPorFuente[fuente]?[dia] ?? 0;
                                      return BarTooltipItem(
                                        '$fuente\n$valor',
                                        TextStyle(
                                          color: colores[rodIndex % colores.length],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= 0 && index < dias.length) {
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            child: Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text(
                                                dias[index].substring(5),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                      reservedSize: 30,
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.black54,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 1,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: Colors.grey.withOpacity(0.2),
                                    strokeWidth: 1,
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                barGroups: List.generate(dias.length, (index) {
                                  final dia = dias[index];
                                  final barRods = <BarChartRodData>[];

                                  int colorIndex = 0;
                                  for (var fuente in datosPorFuente.keys) {
                                    final cantidad = datosPorFuente[fuente]?[dia] ?? 0;
                                    barRods.add(
                                      BarChartRodData(
                                        toY: cantidad.toDouble(),
                                        width: 16,
                                        color: colores[colorIndex % colores.length],
                                        borderRadius: BorderRadius.circular(4),
                                        backDrawRodData: BackgroundBarChartRodData(
                                          show: true,
                                          toY: 20,
                                          color: Colors.grey.withOpacity(0.1),
                                        ),
                                      ),
                                    );
                                    colorIndex++;
                                  }

                                  return BarChartGroupData(
                                    x: index,
                                    groupVertically: true,
                                    barRods: barRods,
                                  );
                                }),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildSelectorFuentes(),
                        ],
                      ),
                    ),
                  ),
                  if (_fuenteSeleccionada != null)
                    _buildGraficaIndividual(_fuenteSeleccionada!),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Leyenda',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3366CC),
                            ),),
                          SizedBox(height: 16),
                          Wrap(
  spacing: 12,
  runSpacing: 8,
  children: datosPorFuente.keys.map((fuente) {
    final color = colores[datosPorFuente.keys.toList().indexOf(fuente) % colores.length];
    return Chip(
      backgroundColor: color.withOpacity(0.2),
      label: Text(
        fuente,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      avatar: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }).toList(),
),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: exportarCSV,
                          icon: const Icon(Icons.download),
                          label: const Text('Exportar CSV'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3366CC),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: exportarPDF,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Exportar PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA4335),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
),
    );
  }
}