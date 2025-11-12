import 'package:flutter/material.dart';
import '../services/monitoreo_service.dart';

class MonitoreoLogScreen extends StatefulWidget {
  const MonitoreoLogScreen({super.key});

  @override
  State<MonitoreoLogScreen> createState() => _MonitoreoLogScreenState();
}

class _MonitoreoLogScreenState extends State<MonitoreoLogScreen> {
  final MonitoreoService _monitoreoService = MonitoreoService();
  late Future<List<Map<String, dynamic>>> _futureMonitoreo;

  @override
  void initState() {
    super.initState();
    _futureMonitoreo = _monitoreoService.fetchMonitoreo();
  }

  void _confirmarPublicacion(Map<String, dynamic> r) async {
    final tipoController = TextEditingController(text: 'Manual');
    final nivelController = TextEditingController(text: 'medio');
    final descripcionController = TextEditingController(text: r['descripcion']);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.blue[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.blue.shade300, width: 2),
        ),
        title: const Text("¿Publicar este registro como alerta?",
            style: TextStyle(color: Colors.blue)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("🌍 Ubicación: ${r['ubicacion']}",
                  style: TextStyle(color: Colors.blue[800])),
              Text("📅 Fecha: ${r['fecha']?.toString().split('T')[0]}",
                  style: TextStyle(color: Colors.blue[800])),
              const SizedBox(height: 8),
              Text("🌡️ Temp: ${r['temperatura']}°C",
                  style: TextStyle(color: Colors.blue[800])),
              Text("💧 Humedad: ${r['humedad']}%",
                  style: TextStyle(color: Colors.blue[800])),
              Text("☔ Precipitación: ${r['precipitacion']} mm",
                  style: TextStyle(color: Colors.blue[800])),
              Text("🌬️ Viento: ${r['viento']} km/h",
                  style: TextStyle(color: Colors.blue[800])),
              Text("📡 Fuente: ${r['fuente'] ?? 'desconocida'}",
                  style: TextStyle(color: Colors.blue[800])),
              const Divider(height: 24, color: Colors.blue),
              TextField(
                controller: tipoController,
                decoration: InputDecoration(
                  labelText: 'Tipo de alerta',
                  labelStyle: TextStyle(color: Colors.blue[700]),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue.shade300),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue.shade700),
                  ),
                ),
              ),
              TextField(
                controller: nivelController,
                decoration: InputDecoration(
                  labelText: 'Nivel de alerta',
                  labelStyle: TextStyle(color: Colors.blue[700]),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue.shade300),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue.shade700),
                  ),
                ),
              ),
              TextField(
                controller: descripcionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  labelStyle: TextStyle(color: Colors.blue[700]),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue.shade300),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue.shade700),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar",
                style: TextStyle(color: Colors.blue)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.upload, color: Colors.white),
            label: const Text("Publicar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final success = await _monitoreoService.publicarComoAlertaCustom(
        id: r['id'],
        tipo: tipoController.text.trim(),
        nivel: nivelController.text.trim(),
        descripcion: descripcionController.text.trim(),
      );

      final msg = success ? '✅ Alerta publicada con éxito' : '❌ Error al publicar alerta';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: success ? Colors.blue : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

      setState(() => _futureMonitoreo = _monitoreoService.fetchMonitoreo());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('📡 Datos de Monitoreo',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureMonitoreo,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.blue[800])),
            );
          }

          final registros = snapshot.data!;
          return ListView.builder(
            itemCount: registros.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (_, index) {
              final r = registros[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.blue[50],
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {},
                  splashColor: Colors.blue.withOpacity(0.2),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text("🧭 ${r['ubicacion']}",
                        style: TextStyle(
                            color: Colors.blue[900],
                            fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📅 ${r['fecha']?.toString().split('T')[0]}",
                            style: TextStyle(color: Colors.blue[800])),
                        const SizedBox(height: 4),
                        Text(
                            "🌡️ Temp: ${r['temperatura']}°C  💧 Humedad: ${r['humedad']}%",
                            style: TextStyle(color: Colors.blue[800])),
                        Text(
                            "☔ Precip: ${r['precipitacion']} mm  🌬️ Viento: ${r['viento']} km/h",
                            style: TextStyle(color: Colors.blue[800])),
                        if (r['descripcion'] != null &&
                            r['descripcion'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text("📝 ${r['descripcion']}",
                                style: TextStyle(color: Colors.blue[800])),
                          ),
                        Text("📡 Fuente: ${r['fuente'] ?? 'desconocida'}",
                            style: TextStyle(color: Colors.blue[700])),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.cloud_upload, color: Colors.blue),
                      tooltip: 'Publicar como alerta',
                      onPressed: () => _confirmarPublicacion(r),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}