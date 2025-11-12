import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../config/global_config.dart';

class EstadisticasFuentesScreen extends StatefulWidget {
  const EstadisticasFuentesScreen({super.key});

  @override
  State<EstadisticasFuentesScreen> createState() => _EstadisticasFuentesScreenState();
}

class _EstadisticasFuentesScreenState extends State<EstadisticasFuentesScreen> {
  List<Map<String, dynamic>> datos = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _fuenteSeleccionada;
  final List<Color> _colores = [
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
      _fuenteSeleccionada = null;
    });

    try {
      final url = Uri.parse('${GlobalConfig.baseURL}/api/monitoreo/estadisticas/fuentes');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final List decoded = jsonDecode(res.body);
        setState(() {
          datos = decoded.map((d) => {
            'fuente': d['fuente'] ?? 'desconocida',
            'cantidad': int.tryParse(d['cantidad'].toString()) ?? 0,
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Error ${res.statusCode} al obtener datos');
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
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> exportarCSV() async {
    final filas = [
      ['Fuente', 'Cantidad', 'Porcentaje'],
      ...datos.map((d) {
        final total = datos.fold<int>(0, (suma, item) => suma + (item['cantidad'] as int));
        final porcentaje = ((d['cantidad'] / total) * 100).toStringAsFixed(2);
        return [d['fuente'], d['cantidad'], '$porcentaje%'];
      })
    ];
    
    final csv = const ListToCsvConverter().convert(filas);
    final blob = html.Blob([csv]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "estadisticas_fuentes_${DateTime.now().toIso8601String()}.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> exportarPDF() async {
    final pdf = pw.Document();
    final total = datos.fold<int>(0, (suma, item) => suma + (item['cantidad'] as int));

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Estadísticas de Fuentes de Datos',
                style: pw.TextStyle(
                  fontSize: 24,
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
              headers: ['Fuente', 'Cantidad', 'Porcentaje'],
              data: datos.map((d) {
                final porcentaje = ((d['cantidad'] / total) * 100).toStringAsFixed(2);
                return [d['fuente'], d['cantidad'].toString(), '$porcentaje%'];
              }).toList(),
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
              'Total registros: $total',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _exportarFuentePDF(Map<String, dynamic> fuente) async {
    final pdf = pw.Document();
    final total = datos.fold<int>(0, (suma, item) => suma + (item['cantidad'] as int));
    final porcentaje = ((fuente['cantidad'] / total) * 100).toStringAsFixed(2);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Detalle de Fuente',
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
                headers: ['Campo', 'Valor'],
                data: [
                  ['Fuente', fuente['fuente']],
                  ['Cantidad', fuente['cantidad'].toString()],
                  ['Porcentaje del total', '$porcentaje%'],
                  ['Comparación con total', '${(fuente['cantidad'] / total * 100).toStringAsFixed(1)}%'],
                ],
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
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _exportarFuenteCSV(Map<String, dynamic> fuente) async {
    final total = datos.fold<int>(0, (suma, item) => suma + (item['cantidad'] as int));
    final porcentaje = ((fuente['cantidad'] / total) * 100).toStringAsFixed(2);

    final csvData = [
      ['Campo', 'Valor'],
      ['Fuente', fuente['fuente']],
      ['Cantidad', fuente['cantidad']],
      ['Porcentaje del total', '$porcentaje%'],
      ['Comparación con total', '${(fuente['cantidad'] / total * 100).toStringAsFixed(1)}%'],
      ['Total registros', total]
    ];

    final csv = const ListToCsvConverter().convert(csvData);
    final blob = html.Blob([csv]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "detalle_fuente_${fuente['fuente'].toString().replaceAll(' ', '_')}_${DateTime.now().toIso8601String()}.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Widget _buildSelectorFuentes() {
    return Column(
      children: [
        Text('Ver detalles por fuente:',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700)),
        SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: datos.map((d) {
              final index = datos.indexOf(d);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(d['fuente']),
                  selected: _fuenteSeleccionada == d['fuente'],
                  onSelected: (selected) {
                    setState(() {
                      _fuenteSeleccionada = selected ? d['fuente'] : null;
                    });
                  },
                  selectedColor: _colores[index % _colores.length],
                  labelStyle: TextStyle(
                    color: _fuenteSeleccionada == d['fuente']
                        ? Colors.white
                        : Colors.grey.shade800,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetalleFuente(Map<String, dynamic> fuente) {
    final total = datos.fold<int>(0, (suma, item) => suma + (item['cantidad'] as int));
    final porcentaje = ((fuente['cantidad'] / total) * 100).toStringAsFixed(1);
    final index = datos.indexWhere((d) => d['fuente'] == fuente['fuente']);

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
                    Icon(Icons.insights, color: _colores[index % _colores.length]),
                    SizedBox(width: 8),
                    Text('Detalle de ${fuente['fuente']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatItem('Total registros', fuente['cantidad'].toString()),
                      _buildStatItem('Porcentaje del total', '$porcentaje%'),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 100,
                    child: CustomPaint(
                      painter: _GaugePainter(
                        percentage: double.parse(porcentaje),
                        color: _colores[index % _colores.length],
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
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800)),
        ],
      ),
    );
  }

  Widget _buildBadge(String fuente) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        fuente.length > 10 ? '${fuente.substring(0, 8)}..' : fuente,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = datos.fold<int>(0, (suma, item) => suma + (item['cantidad'] as int));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas de Fuentes'),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3366CC),
                    ),
                    child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(  // Añade este widget
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
                          const Text(
                            'Distribución por Fuente',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3366CC),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 250,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 60,
                                sections: datos.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final d = entry.value;
                                  final porcentaje = ((d['cantidad'] / total) * 100).toStringAsFixed(1);
                                  return PieChartSectionData(
                                    value: d['cantidad'].toDouble(),
                                    title: '$porcentaje%',
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    radius: 80,
                                    color: _colores[index % _colores.length],
                                    badgeWidget: _buildBadge(d['fuente']),
                                    badgePositionPercentageOffset: 0.98,
                                  );
                                }).toList(),
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
                    _buildDetalleFuente(datos.firstWhere((d) => d['fuente'] == _fuenteSeleccionada)),
                  const SizedBox(height: 20),
                  ListView.builder(
                    shrinkWrap: true,  // Importante para que funcione dentro de Column
                    physics: const NeverScrollableScrollPhysics(),  // Deshabilita el scroll interno
                    itemCount: datos.length,
                    itemBuilder: (context, index) {
                      final d = datos[index];
                      final porcentaje = ((d['cantidad'] / total) * 100).toStringAsFixed(1);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        elevation: 2,
                        child: ListTile(
                          leading: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _colores[index % _colores.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(d['fuente']),
                          subtitle: Text('$porcentaje% del total'),
                          trailing: Text(
                            d['cantidad'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: exportarCSV,
                        icon: const Icon(Icons.download),
                        label: const Text('Exportar CSV'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3366CC),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),  // Espacio adicional al final
                ],
              ),
            ),
),
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