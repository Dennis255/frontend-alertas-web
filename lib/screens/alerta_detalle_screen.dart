import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import '../models/alerta_model.dart';
import '../services/alerta_service.dart';

class AlertaDetalleScreen extends StatefulWidget {
  final Alerta alerta;
  final String rol;

  const AlertaDetalleScreen({
    super.key,
    required this.alerta,
    required this.rol,
  });

  @override
  State<AlertaDetalleScreen> createState() => _AlertaDetalleScreenState();
}

class _AlertaDetalleScreenState extends State<AlertaDetalleScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  Uint8List? _capturaMapa;
  final Map<String, String> _odsInfo = {
    'ODS 1': 'Fin de la pobreza: Medidas para proteger a los más vulnerables',
    'ODS 2': 'Hambre cero: Protección de cultivos y seguridad alimentaria',
    'ODS 3': 'Salud y bienestar: Protección de la salud ante desastres',
    'ODS 6': 'Agua limpia y saneamiento: Gestión eficiente del agua',
    'ODS 9': 'Industria, innovación e infraestructura: Infraestructura resiliente',
    'ODS 11': 'Ciudades sostenibles: Comunidades seguras y resilientes',
    'ODS 12': 'Producción y consumo responsables: Uso sostenible de recursos',
    'ODS 13': 'Acción por el clima: Medidas contra el cambio climático',
    'ODS 17': 'Alianzas para lograr los objetivos: Cooperación institucional',
  };

  Future<void> _capturarMapa() async {
    final imagen = await _screenshotController.capture();
    if (imagen != null) {
      setState(() {
        _capturaMapa = imagen;
      });
    }
  }

  Future<void> _exportarPDF(BuildContext context) async {
    await _capturarMapa();

    final doc = pw.Document();
    final fechaStr = widget.alerta.fecha.toLocal().toString().split('.')[0];
    final recomendaciones = _generarRecomendaciones();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Row(
                children: [
                  pw.Text('🛰️ ', style: pw.TextStyle(fontSize: 24)),
                  pw.Text('Sistema de Alertas Tempranas', 
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.Text('📄 Reporte de alerta generado el: ${DateTime.now().toLocal()}'),
            pw.Divider(),
            pw.Text('🔔 Tipo: ${widget.alerta.tipo}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('🔴 Nivel: ${widget.alerta.nivel}', 
              style: pw.TextStyle(color: _getPdfColorForNivel(widget.alerta.nivel))),
            pw.Text('📍 Ubicación: ${widget.alerta.ubicacion}'),
            pw.Text('📅 Fecha del evento: $fechaStr'),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue800),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Text('📝 Descripción: ${widget.alerta.descripcion}'),
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              children: [
                if (widget.alerta.temperatura != null) 
                  _buildWeatherIconText('🌡️', 'Temp: ${widget.alerta.temperatura}°C'),
                if (widget.alerta.humedad != null) 
                  _buildWeatherIconText('💧', 'Humedad: ${widget.alerta.humedad}%'),
              ],
            ),
            pw.Row(
              children: [
                if (widget.alerta.precipitacion != null) 
                  _buildWeatherIconText('☔', 'Precipitación: ${widget.alerta.precipitacion} mm'),
                if (widget.alerta.viento != null) 
                  _buildWeatherIconText('🌬️', 'Viento: ${widget.alerta.viento} km/h'),
              ],
            ),
            if (_capturaMapa != null) ...[
              pw.SizedBox(height: 20),
              pw.Text('🗺️ Mapa del evento:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Image(pw.MemoryImage(_capturaMapa!), height: 200),
              ),
            ],
            pw.SizedBox(height: 20),
            pw.Text('📌 Recomendaciones alineadas a los ODS:', 
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 10),
            ...recomendaciones.map((r) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Expanded(
                      child: pw.Text(r['recomendacion']!, 
                        style: pw.TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text('(${r['ods']!}: ${_odsInfo[r['ods']] ?? ''})',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                pw.SizedBox(height: 8),
              ],
            )),
            pw.SizedBox(height: 20),
            pw.Text('ℹ️ Los Objetivos de Desarrollo Sostenible (ODS) son un llamado universal a la acción para poner fin a la pobreza, proteger el planeta y garantizar que todas las personas gocen de paz y prosperidad.',
              style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
          ],
        ),
      ),
    );

    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Vista previa del PDF'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('¿Deseas guardar este reporte en PDF?'),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('El PDF incluirá:\n- Detalles de la alerta\n- Mapa de ubicación\n- Recomendaciones ODS\n- Información meteorológica',
                  style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar PDF'),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      await Printing.sharePdf(bytes: await doc.save(), filename: 'alerta_${widget.alerta.id}.pdf');
    }
  }

  pw.Widget _buildWeatherIconText(String icon, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(right: 20),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(icon),
          pw.SizedBox(width: 4),
          pw.Text(text, style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  List<Map<String, String>> _generarRecomendaciones() {
    final List<Map<String, String>> recomendaciones = [];
    final tipo = widget.alerta.tipo.toLowerCase();
    final nivel = widget.alerta.nivel.toLowerCase();

    if (tipo.contains('lluvia')) {
      recomendaciones.add({
        'ods': 'ODS 11',
        'recomendacion': 'Evitar zonas inundables y revisar sistemas de drenaje para proteger ciudades y comunidades.'
      });
      recomendaciones.add({
        'ods': 'ODS 13',
        'recomendacion': 'Reforzar techos y estructuras vulnerables ante lluvias intensas.'
      });
      if (nivel == 'alto') {
        recomendaciones.add({
          'ods': 'ODS 3',
          'recomendacion': 'Preparar rutas de evacuación seguras y puntos de encuentro para la comunidad.'
        });
      }
    } else if (tipo.contains('helada')) {
      recomendaciones.add({
        'ods': 'ODS 2',
        'recomendacion': 'Proteger cultivos sensibles con coberturas térmicas y riego por aspersión.'
      });
      recomendaciones.add({
        'ods': 'ODS 13',
        'recomendacion': 'Implementar sistemas de monitoreo de temperatura en zonas agrícolas críticas.'
      });
      if (nivel == 'alto') {
        recomendaciones.add({
          'ods': 'ODS 1',
          'recomendacion': 'Activar protocolos de ayuda a agricultores de pequeña escala.'
        });
      }
    } else if (tipo.contains('sequía')) {
      recomendaciones.add({
        'ods': 'ODS 6',
        'recomendacion': 'Promover sistemas de riego eficientes como el riego por goteo.'
      });
      recomendaciones.add({
        'ods': 'ODS 12',
        'recomendacion': 'Implementar sistemas de captación y reutilización de agua de lluvia.'
      });
      if (nivel == 'alto') {
        recomendaciones.add({
          'ods': 'ODS 13',
          'recomendacion': 'Activar planes de emergencia hídrica con distribución controlada.'
        });
      }
    } else if (tipo.contains('viento')) {
      recomendaciones.add({
        'ods': 'ODS 9',
        'recomendacion': 'Revisar infraestructura crítica como torres de comunicación y tendido eléctrico.'
      });
      recomendaciones.add({
        'ods': 'ODS 11',
        'recomendacion': 'Asegurar techos, carteles y estructuras comunitarias vulnerables.'
      });
    }

    // Recomendaciones adicionales según rol
    if (widget.rol == 'admin') {
      recomendaciones.add({
        'ods': 'ODS 17',
        'recomendacion': 'Revisar reportes técnicos y coordinar con instituciones especializadas.'
      });
    }
    if (widget.rol == 'autoridad') {
      recomendaciones.add({
        'ods': 'ODS 11',
        'recomendacion': 'Coordinar sistemas de alerta temprana con líderes comunitarios.'
      });
    }

    return recomendaciones;
  }

  PdfColor _getPdfColorForNivel(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'alto': return PdfColors.red;
      case 'medio': return PdfColor.fromInt(0xFFFFA500); // Naranja
      case 'bajo': return PdfColor.fromInt(0xFFDAA520); // Amarillo oscuro
      default: return PdfColors.grey;
    }
  }

  Color _getColorForNivel(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'alto': return Colors.red;
      case 'medio': return Colors.orange;
      case 'bajo': return Colors.yellow.shade700;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final coord = widget.alerta.ubicacion.split(',');
    final LatLng? punto = coord.length == 2
        ? LatLng(double.tryParse(coord[0]) ?? 0.0, double.tryParse(coord[1]) ?? 0.0)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Alerta'),
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
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: () => _exportarPDF(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.lightBlue.shade100],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getIconForAlertType(widget.alerta.tipo),
                            color: _getColorForNivel(widget.alerta.nivel),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.alerta.tipo,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailItem('📍', 'Ubicación', widget.alerta.ubicacion),
                      _buildDetailItem('🔴', 'Nivel', widget.alerta.nivel,
                        textColor: _getColorForNivel(widget.alerta.nivel)),
                      _buildDetailItem('📅', 'Fecha', 
                        widget.alerta.fecha.toLocal().toString().split('.')[0]),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "📝 ${widget.alerta.descripcion}",
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 Datos Meteorológicos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 20,
                        runSpacing: 12,
                        children: [
                          if (widget.alerta.temperatura != null)
                            _buildWeatherCard('🌡️', 'Temperatura', '${widget.alerta.temperatura}°C'),
                          if (widget.alerta.humedad != null)
                            _buildWeatherCard('💧', 'Humedad', '${widget.alerta.humedad}%'),
                          if (widget.alerta.precipitacion != null)
                            _buildWeatherCard('☔', 'Precipitación', '${widget.alerta.precipitacion} mm'),
                          if (widget.alerta.viento != null)
                            _buildWeatherCard('🌬️', 'Viento', '${widget.alerta.viento} km/h'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (punto != null) ...[
                const Text(
                  '🗺️ Ubicación del Evento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Coordenadas: ${widget.alerta.ubicacion}',
                  style: TextStyle(color: Colors.blue.shade800),
                ),
                const SizedBox(height: 12),
                Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade200,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 220,
                        child: FlutterMap(
                          options: MapOptions(center: punto, zoom: 13),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c'],
                              userAgentPackageName: 'com.tesis.alertas',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: punto,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🛡️ Recomendaciones ODS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Acciones alineadas con los Objetivos de Desarrollo Sostenible:',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ..._generarRecomendaciones().map((r) => Column(
                        children: [
                          _buildRecommendationCard(r['ods']!, r['recomendacion']!),
                          const SizedBox(height: 8),
                        ],
                      )),
                      const SizedBox(height: 12),
                      Text(
                        'ℹ️ Los Objetivos de Desarrollo Sostenible (ODS) son un llamado universal a la acción para poner fin a la pobreza, proteger el planeta y garantizar que todas las personas gocen de paz y prosperidad.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (!widget.alerta.vistaPorUsuario)
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final exito = await AlertaService().marcarComoVista(widget.alerta.id);
                      if (exito) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Alerta marcada como vista')),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('❌ Error al marcar la alerta')),
                        );
                      }
                    },
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      "Marcar como vista",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                )
              else
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Text(
                      '✅ Esta alerta ya ha sido revisada',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String icon, String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: textColor ?? Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(String icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.blue.shade800,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.blue.shade900,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(String ods, String recomendacion) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ods,
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _odsInfo[ods] ?? '',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recomendacion,
            style: TextStyle(
              color: Colors.blue.shade900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForAlertType(String tipo) {
    if (tipo.toLowerCase().contains('lluvia')) return Icons.umbrella;
    if (tipo.toLowerCase().contains('helada')) return Icons.ac_unit;
    if (tipo.toLowerCase().contains('sequía')) return Icons.water_drop;
    if (tipo.toLowerCase().contains('viento')) return Icons.air;
    return Icons.warning;
  }
}