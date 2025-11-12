// lib/services/monitoreo_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/global_config.dart';

class MonitoreoService {
  //IP
  final String _baseUrl = '${GlobalConfig.baseURL}/api/monitoreo';

  Future<List<Map<String, dynamic>>> fetchMonitoreo() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Error al cargar datos de monitoreo');
    }
  }

  Future<bool> publicarComoAlertaCustom({
    required int id,
    required String tipo,
    required String nivel,
    required String descripcion,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/publicar/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tipo': tipo,
        'nivel': nivel,
        'descripcion': descripcion,
      }),
    );
    return response.statusCode == 201;
  }
}
