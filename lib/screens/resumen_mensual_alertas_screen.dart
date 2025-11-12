import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/global_config.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'dart:html' as html;

class ResumenMensualAlertasScreen extends StatefulWidget {
  const ResumenMensualAlertasScreen({super.key});

  @override
  State<ResumenMensualAlertasScreen> createState() => _ResumenMensualAlertasScreenState();
}

class _ResumenMensualAlertasScreenState extends State<ResumenMensualAlertasScreen> {
  List<Map<String, dynamic>> datos = [];
  int maxCantidad = 0;
  int minCantidad = 0;
  String periodo = 'mensual'; // puede ser 'mensual', 'semanal', 'diario'
  String? _periodoDetalle;

  // Colores personalizados para el tema azul/celeste
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = const Color(0xFFBBDEFB);
  final Color accentColor = const Color(0xFF2196F3);
  final Color backgroundColor = const Color(0xFFE3F2FD);

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    final uri = Uri.parse('${GlobalConfig.baseURL}/api/alertas/evolucion?periodo=$periodo');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      final agrupado = <String, int>{};
      for (var row in data) {
        final mes = row['periodo']?.toString() ?? '';
        final cantidad = int.tryParse(row['cantidad'].toString()) ?? 0;
        agrupado[mes] = (agrupado[mes] ?? 0) + cantidad;
      }

      final resultado = agrupado.entries.map((e) => {
        'periodo': e.key,
        'cantidad': e.value,
      }).toList();

      resultado.sort((a, b) => (a['periodo'] as String).compareTo(b['periodo'] as String));

      final max = resultado.reduce((a, b) => (a['cantidad'] as int) > (b['cantidad'] as int) ? a : b);
      final min = resultado.reduce((a, b) => (a['cantidad'] as int) < (b['cantidad'] as int) ? a : b);

      setState(() {
        datos = resultado;
        maxCantidad = max['cantidad'] as int;
        minCantidad = min['cantidad'] as int;
      });
    } else {
      print('❌ Error al cargar datos');
    }
  }

  void cambiarPeriodo(String nuevo) {
    setState(() {
      periodo = nuevo;
      datos = [];
      _periodoDetalle = null;
    });
    cargarDatos();
  }

  // Métodos para exportar datos
  Future<void> _exportarPDF() async {
    final pdf = pw.Document();
    final maxEntry = datos.reduce((a, b) => (a['cantidad'] as int) > (b['cantidad'] as int) ? a : b);
    final minEntry = datos.reduce((a, b) => (a['cantidad'] as int) < (b['cantidad'] as int) ? a : b);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Resumen ${periodo == 'diario' ? 'Diario' : periodo == 'semanal' ? 'Semanal' : 'Mensual'} de Alertas',
                  style: pw.TextStyle(
                    fontSize: 18,
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
                headers: ['Período', 'Cantidad de Alertas'],
                data: datos.map((d) => [d['periodo'], d['cantidad'].toString()]).toList(),
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
              pw.Text('Pico más alto: ${maxEntry['periodo']} (${maxEntry['cantidad']} alertas)'),
              pw.Text('Pico más bajo: ${minEntry['periodo']} (${minEntry['cantidad']} alertas)'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _exportarCSV() async {
    final csvData = [
      ['Período', 'Cantidad de Alertas'],
      ...datos.map((d) => [d['periodo'], d['cantidad']])
    ];

    final csv = const ListToCsvConverter().convert(csvData);
    final blob = html.Blob([csv]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "resumen_alertas_${periodo}_${DateTime.now().toIso8601String()}.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Widget _buildSelectorPeriodosDetalle() {
    return Column(
      children: [
        Text('Ver detalles por período:',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey[800])),
        SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: datos.map((d) {
              final isSelected = _periodoDetalle == d['periodo'];
              final isMax = d['cantidad'] == maxCantidad;
              final isMin = d['cantidad'] == minCantidad;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(periodo == 'mensual'
                      ? d['periodo'].toString().substring(5)
                      : d['periodo'].toString()),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _periodoDetalle = selected ? d['periodo'] : null;
                    });
                  },
                  selectedColor: isMax
                      ? Colors.redAccent
                      : isMin
                          ? Colors.blueAccent
                          : accentColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.blueGrey[800],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetallePeriodo(String periodoDetalle) {
    final dato = datos.firstWhere((d) => d['periodo'] == periodoDetalle);
    final esMax = dato['cantidad'] == maxCantidad;
    final esMin = dato['cantidad'] == minCantidad;

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
                    Icon(
                        esMax
                            ? Icons.trending_up
                            : esMin
                                ? Icons.trending_down
                                : Icons.show_chart,
                        color: esMax
                            ? Colors.redAccent
                            : esMin
                                ? Colors.blueAccent
                                : accentColor),
                    SizedBox(width: 8),
                    Text('Detalle del período',
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
                      onPressed: () => _exportarDetallePDF(dato),
                      tooltip: 'Exportar a PDF',
                    ),
                    IconButton(
                      icon: Icon(Icons.insert_drive_file, size: 20),
                      onPressed: () => _exportarDetalleCSV(dato),
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
                      _buildStatItem('Período', periodoDetalle),
                      _buildStatItem('Total alertas', dato['cantidad'].toString()),
                      _buildStatItem(
                          'Tendencia',
                          esMax
                              ? 'Pico máximo'
                              : esMin
                                  ? 'Pico mínimo'
                                  : 'Intermedio'),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 100,
                    child: CustomPaint(
                      painter: _BarIndicatorPainter(
                        value: dato['cantidad'].toDouble(),
                        maxValue: maxCantidad.toDouble(),
                        color: esMax
                            ? Colors.redAccent
                            : esMin
                                ? Colors.blueAccent
                                : accentColor,
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

  Future<void> _exportarDetallePDF(Map<String, dynamic> dato) async {
    final pdf = pw.Document();
    final esMax = dato['cantidad'] == maxCantidad;
    final esMin = dato['cantidad'] == minCantidad;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Detalle de Período',
                  style: pw.TextStyle(
                    fontSize: 18,
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
                  ['Período', dato['periodo']],
                  ['Cantidad de Alertas', dato['cantidad'].toString()],
                  ['Tendencia', esMax ? 'Pico máximo' : esMin ? 'Pico mínimo' : 'Intermedio'],
                  ['Comparación', '${(dato['cantidad'] / maxCantidad * 100).toStringAsFixed(1)}% del pico máximo'],
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
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _exportarDetalleCSV(Map<String, dynamic> dato) async {
    final esMax = dato['cantidad'] == maxCantidad;
    final esMin = dato['cantidad'] == minCantidad;

    final csvData = [
      ['Campo', 'Valor'],
      ['Período', dato['periodo']],
      ['Cantidad de Alertas', dato['cantidad']],
      ['Tendencia', esMax ? 'Pico máximo' : esMin ? 'Pico mínimo' : 'Intermedio'],
      ['Comparación con pico máximo', '${(dato['cantidad'] / maxCantidad * 100).toStringAsFixed(1)}%'],
    ];

    final csv = const ListToCsvConverter().convert(csvData);
    final blob = html.Blob([csv]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "detalle_periodo_${dato['periodo'].toString().replaceAll('/', '-')}_${DateTime.now().toIso8601String()}.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(fontSize: 14, color: Colors.blueGrey[800])),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('📈 Análisis de alertas climáticas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: _exportarPDF,
            tooltip: 'Exportar a PDF',
          ),
          IconButton(
            icon: Icon(Icons.insert_drive_file),
            onPressed: _exportarCSV,
            tooltip: 'Exportar a CSV',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onSelected: cambiarPeriodo,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'diario', child: Text('Por día')),
              PopupMenuItem(value: 'semanal', child: Text('Por semana')),
              PopupMenuItem(value: 'mensual', child: Text('Por mes')),
            ],
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: datos.isEmpty
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen ${periodo == 'diario' ? 'diario' : periodo == 'semanal' ? 'semanal' : 'mensual'} de alertas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueGrey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, secondaryColor.withOpacity(0.3)],
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 260,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, _) {
                                      final index = value.toInt();
                                      if (index < 0 || index >= datos.length) return const SizedBox();
                                      final texto = datos[index]['periodo'].toString();
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          periodo == 'mensual' ? texto.substring(5) : texto,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 10,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 1,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.blueGrey.withOpacity(0.1),
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border(
                                  bottom: BorderSide(color: primaryColor.withOpacity(0.2)), 
                                  left: BorderSide(color: primaryColor.withOpacity(0.2)),
                                ),
                              ),
                              barGroups: List.generate(datos.length, (i) {
                                final cantidad = datos[i]['cantidad'] as int;
                                final isMax = cantidad == maxCantidad;
                                final isMin = cantidad == minCantidad;
                                return BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: cantidad.toDouble(),
                                      color: isMax
                                          ? Colors.redAccent
                                          : isMin
                                              ? Colors.blueAccent
                                              : accentColor,
                                      width: 16,
                                      borderRadius: BorderRadius.circular(6),
                                      backDrawRodData: BackgroundBarChartRodData(
                                        show: true,
                                        toY: maxCantidad.toDouble(),
                                        color: secondaryColor.withOpacity(0.3),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildSelectorPeriodosDetalle(),
                      ],
                    ),
                  ),
                  if (_periodoDetalle != null)
                    _buildDetallePeriodo(_periodoDetalle!),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueGrey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.trending_up, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Text('Pico más alto: $maxCantidad alertas', 
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blueGrey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.trending_down, color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Text('Pico más bajo: $minCantidad alertas', 
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blueGrey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BarIndicatorPainter extends CustomPainter {
  final double value;
  final double maxValue;
  final Color color;

  _BarIndicatorPainter({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillWidth = (value / maxValue) * size.width;
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Dibuja el fondo
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(8),
      ),
      paint,
    );

    // Dibuja el valor
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, fillWidth, size.height),
        Radius.circular(8),
      ),
      fillPaint,
    );

    // Dibuja el texto
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(value / maxValue * 100).toStringAsFixed(0)}%',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        fillWidth - textPainter.width - 8,
        size.height / 2 - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}