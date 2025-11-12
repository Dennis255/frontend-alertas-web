import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import '../config/global_config.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'dart:html' as html;

class EvolucionLineasScreen extends StatefulWidget {
  const EvolucionLineasScreen({super.key});

  @override
  State<EvolucionLineasScreen> createState() => _EvolucionLineasScreenState();
}

class _EvolucionLineasScreenState extends State<EvolucionLineasScreen> {
  String periodo = 'diario';
  List<String> fechas = [];
  Map<String, List<int>> dataPorTipo = {};
  final tipos = ['Helada', 'Sequía', 'Inundación', 'Otro'];
  bool isLoading = false;
  String? _tipoSeleccionado;

  final Map<String, Color> colores = {
    'Helada': const Color(0xFF4285F4),
    'Sequía': const Color(0xFFEA4335),
    'Inundación': const Color(0xFF34A853),
    'Otro': const Color(0xFFFBBC05),
  };

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      isLoading = true;
      _tipoSeleccionado = null;
    });
    try {
      final uri = Uri.parse('${GlobalConfig.baseURL}/api/alertas/evolucion?periodo=$periodo');
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final List<dynamic> datos = jsonDecode(res.body);
        final fechasSet = <String>{};
        final Map<String, Map<String, int>> agrupado = {};

        for (var item in datos) {
          final tipo = _clasificarTipo(item['tipo']);
          final fecha = item['periodo'];
          final cantidad = int.tryParse(item['cantidad'].toString()) ?? 0;

          fechasSet.add(fecha);
          agrupado[tipo] ??= {};
          agrupado[tipo]![fecha] = cantidad;
        }

        final fechasOrdenadas = fechasSet.toList()..sort();
        final Map<String, List<int>> resultado = {};

        for (var tipo in tipos) {
          resultado[tipo] = fechasOrdenadas.map((fecha) => agrupado[tipo]?[fecha] ?? 0).toList();
        }

        setState(() {
          fechas = fechasOrdenadas;
          dataPorTipo = resultado;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar los datos. Intente nuevamente.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _clasificarTipo(String? tipo) {
    tipo = tipo?.toLowerCase() ?? '';
    if (tipo.contains('helada')) return 'Helada';
    if (tipo.contains('sequía')) return 'Sequía';
    if (tipo.contains('inund')) return 'Inundación';
    return 'Otro';
  }

  List<LineChartBarData> _generarLineas() {
    return tipos.map((tipo) {
      final puntos = dataPorTipo[tipo] ?? [];
      return LineChartBarData(
        spots: List.generate(puntos.length, (i) => FlSpot(i.toDouble(), puntos[i].toDouble())),
        isCurved: true,
        barWidth: 4,
        color: colores[tipo],
        shadow: Shadow(color: colores[tipo]!.withOpacity(0.3), blurRadius: 8),
        belowBarData: BarAreaData(show: true, color: colores[tipo]!.withOpacity(0.1)),
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
            radius: 4,
            color: colores[tipo]!,
            strokeWidth: 2,
            strokeColor: Colors.white,
          ),
        ),
      );
    }).toList();
  }

  int _maxPico() {
    return dataPorTipo.values.expand((list) => list).fold(0, (a, b) => a > b ? a : b);
  }

  int _minPico() {
    final todos = dataPorTipo.values.expand((list) => list).toList();
    return todos.isEmpty ? 0 : todos.reduce((a, b) => a < b ? a : b);
  }

  // Función para exportar todas las gráficas a PDF
  Future<void> _exportarTodoPDF() async {
    final pdf = pw.Document();
    final totalAlertas = dataPorTipo.values.expand((list) => list).fold(0, (a, b) => a + b);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Reporte de Evolución de Alertas',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Período: ${periodo[0].toUpperCase()}${periodo.substring(1)} - Generado el ${DateTime.now().toString().substring(0, 10)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Fecha', ...tipos],
                data: List.generate(fechas.length, (index) {
                  return [
                    fechas[index],
                    ...tipos.map((tipo) => dataPorTipo[tipo]?[index].toString() ?? '0')
                  ];
                }),
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
              pw.SizedBox(height: 20),
              pw.Text(
                'Resumen Estadístico',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Total de alertas: $totalAlertas'),
              pw.Text('Pico más alto: ${_maxPico()} alertas'),
              pw.Text('Pico más bajo: ${_minPico()} alertas'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // Función para exportar todas las gráficas a CSV
  Future<void> _exportarTodoCSV() async {
    final filas = [
      ['Fecha', ...tipos],
      ...List.generate(fechas.length, (index) {
        return [
          fechas[index],
          ...tipos.map((tipo) => dataPorTipo[tipo]?[index].toString() ?? '0')
        ];
      })
    ];

    final csv = const ListToCsvConverter().convert(filas);
    final blob = html.Blob([csv]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "evolucion_alertas_${DateTime.now().toIso8601String()}.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // Función para exportar una gráfica individual a PDF
  Future<void> _exportarTipoPDF(String tipo) async {
    final pdf = pw.Document();
    final datos = dataPorTipo[tipo] ?? [];
    final maxValor = datos.fold(0, (a, b) => a > b ? a : b);
    final total = datos.fold(0, (a, b) => a + b);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Reporte de $tipo',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Período: ${periodo[0].toUpperCase()}${periodo.substring(1)} - Generado el ${DateTime.now().toString().substring(0, 10)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Fecha', 'Cantidad'],
                data: List.generate(fechas.length, (index) {
                  return [fechas[index], datos[index].toString()];
                }),
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
              pw.SizedBox(height: 20),
              pw.Text(
                'Resumen Estadístico',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Total de alertas: $total'),
              pw.Text('Pico más alto: $maxValor alertas'),
              pw.Text('Días con datos: ${datos.where((d) => d > 0).length}'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // Función para exportar una gráfica individual a CSV
  Future<void> _exportarTipoCSV(String tipo) async {
    final datos = dataPorTipo[tipo] ?? [];
    final filas = [
      ['Fecha', 'Cantidad'],
      ...List.generate(fechas.length, (index) {
        return [fechas[index], datos[index].toString()];
      })
    ];

    final csv = const ListToCsvConverter().convert(filas);
    final blob = html.Blob([csv]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "evolucion_${tipo.toLowerCase()}_${DateTime.now().toIso8601String()}.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // Widget para mostrar el detalle de un tipo seleccionado
  Widget _buildDetalleTipo(String tipo) {
    final datos = dataPorTipo[tipo] ?? [];
    final maxValor = datos.fold(0, (a, b) => a > b ? a : b);
    final total = datos.fold(0, (a, b) => a + b);
    final promedio = datos.isNotEmpty ? total / datos.length : 0;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights, color: colores[tipo]),
                    const SizedBox(width: 8),
                    Text(
                      'Detalle de $tipo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colores[tipo],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, size: 20),
                      onPressed: () => _exportarTipoPDF(tipo),
                      tooltip: 'Exportar a PDF',
                    ),
                    IconButton(
                      icon: const Icon(Icons.insert_drive_file, size: 20),
                      onPressed: () => _exportarTipoCSV(tipo),
                      tooltip: 'Exportar a CSV',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatItem('Total alertas', total.toString()),
                      _buildStatItem('Pico más alto', maxValor.toString()),
                      _buildStatItem('Promedio', promedio.toStringAsFixed(1)),
                    ],
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 100,
                    child: CustomPaint(
                      painter: _GaugePainter(
                        percentage: maxValor > 0 ? (total / (maxValor * datos.length)) * 100 : 0,
                        color: colores[tipo]!,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evolución de Alertas'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportarTodoPDF,
            tooltip: 'Exportar todo a PDF',
          ),
          IconButton(
            icon: const Icon(Icons.insert_drive_file),
            onPressed: _exportarTodoCSV,
            tooltip: 'Exportar todo a CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F7FA), Color(0xFFE4E7EB)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        'Comparativo de Alertas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Visualiza la evolución de alertas por tipo en el tiempo. Identifica tendencias y picos críticos.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Periodo:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButton<String>(
                                value: periodo,
                                isExpanded: true,
                                underline: const SizedBox(),
                                icon: const Icon(Icons.arrow_drop_down),
                                style: const TextStyle(color: Colors.black87),
                                onChanged: (val) {
                                  setState(() => periodo = val!);
                                  _cargarDatos();
                                },
                                items: ['diario', 'semanal', 'mensual']
                                    .map((p) => DropdownMenuItem<String>(
                                          value: p,
                                          child: Text(
                                            p[0].toUpperCase() + p.substring(1),
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
                            ),
                            SizedBox(height: 16),
                            Text('Cargando datos...'),
                          ],
                        ),
                      )
                    : fechas.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.warning, size: 48, color: Colors.amber),
                                SizedBox(height: 16),
                                Text('No hay datos disponibles'),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 300,
                                          child: LineChart(
                                            LineChartData(
                                              lineBarsData: _generarLineas(),
                                              titlesData: FlTitlesData(
                                                bottomTitles: AxisTitles(
                                                  sideTitles: SideTitles(
                                                    showTitles: true,
                                                    getTitlesWidget: (val, meta) {
                                                      final i = val.toInt();
                                                      if (i >= 0 && i < fechas.length) {
                                                        final label = fechas[i].substring(5);
                                                        return Padding(
                                                          padding: const EdgeInsets.only(top: 8),
                                                          child: Text(
                                                            label,
                                                            style: const TextStyle(
                                                              fontSize: 10,
                                                              color: Colors.grey,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                      return const SizedBox.shrink();
                                                    },
                                                    reservedSize: 28,
                                                  ),
                                                ),
                                                leftTitles: AxisTitles(
                                                  sideTitles: SideTitles(
                                                    showTitles: true,
                                                    interval: _maxPico() > 10 ? (_maxPico() / 5).ceilToDouble() : 1,
                                                    getTitlesWidget: (value, meta) {
                                                      return Text(
                                                        value.toInt().toString(),
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.grey,
                                                        ),
                                                      );
                                                    },
                                                    reservedSize: 32,
                                                  ),
                                                ),
                                                rightTitles: const AxisTitles(),
                                                topTitles: const AxisTitles(),
                                              ),
                                              borderData: FlBorderData(
                                                show: true,
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                  width: 1,
                                                ),
                                              ),
                                              gridData: FlGridData(
                                                show: true,
                                                drawVerticalLine: true,
                                                horizontalInterval: _maxPico() > 10 ? (_maxPico() / 5).ceilToDouble() : 1,
                                                verticalInterval: 1,
                                                getDrawingHorizontalLine: (value) => FlLine(
                                                  color: Colors.grey.shade200,
                                                  strokeWidth: 1,
                                                ),
                                                getDrawingVerticalLine: (value) => FlLine(
                                                  color: Colors.grey.shade200,
                                                  strokeWidth: 1,
                                                ),
                                              ),
                                              minY: 0,
                                              maxY: _maxPico() * 1.2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Wrap(
                                          spacing: 16,
                                          runSpacing: 8,
                                          alignment: WrapAlignment.center,
                                          children: tipos.map((tipo) {
                                            return ChoiceChip(
                                              label: Text(tipo),
                                              selected: _tipoSeleccionado == tipo,
                                              onSelected: (selected) {
                                                setState(() {
                                                  _tipoSeleccionado = selected ? tipo : null;
                                                });
                                              },
                                              selectedColor: colores[tipo],
                                              labelStyle: TextStyle(
                                                color: _tipoSeleccionado == tipo
                                                    ? Colors.white
                                                    : colores[tipo],
                                              ),
                                              avatar: CircleAvatar(
                                                backgroundColor: _tipoSeleccionado == tipo
                                                    ? Colors.white
                                                    : colores[tipo],
                                                radius: 8,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_tipoSeleccionado != null)
                                  _buildDetalleTipo(_tipoSeleccionado!),
                                if (dataPorTipo.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildStatCard(Icons.arrow_upward, 'Pico más alto', '${_maxPico()} alertas', Colors.red),
                                          _buildStatCard(Icons.arrow_downward, 'Pico más bajo', '${_minPico()} alertas', Colors.green),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color color;

  _GaugePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 10;
    final startAngle = -pi * 0.8;
    const sweepAngle = pi * 1.6;

    // Fondo del gauge
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Parte rellena del gauge
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Dibujar el fondo completo
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    // Dibujar el porcentaje
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * (percentage / 100),
      false,
      fillPaint,
    );

    // Texto del porcentaje
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${percentage.toStringAsFixed(1)}%',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}