import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alerta_model.dart'; // ✅ Asegúrate de tener alerta_model.dart en /lib/models
import '../config/global_config.dart';

class AlertaService {
  //cambiar la IP
  final String _baseUrl = '${GlobalConfig.baseURL}/api/alertas'; // ⚠️ Cambia esta IP si accedes desde otro dispositivo

  // ✅ Obtener todas las alertas
  Future<List<Alerta>> fetchAlertas() async {
    final url = Uri.parse(_baseUrl);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Alerta.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar alertas');
    }
  }

  // ✅ Crear nueva alerta
  Future<bool> createAlerta({
    required String tipo,
    required String nivel,
    required String ubicacion,
    required String descripcion,
    double? temperatura,
    double? humedad,
    double? precipitacion,
    double? viento,
    required String zona, //
  }) async {
    final url = Uri.parse(_baseUrl);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tipo': tipo,
        'nivel': nivel,
        'ubicacion': ubicacion,
        'descripcion': descripcion,
        'temperatura': temperatura,
        'humedad': humedad,
        'precipitacion': precipitacion,
        'viento': viento,
        'zona': zona,
      }),
    );

    return response.statusCode == 201;
  }

  // ✅ Buscar alertas por tipo, ubicación o nivel
  Future<List<Alerta>> buscarAlertas({
    String? tipo,
    String? ubicacion,
    String? nivel,
  }) async {
    String query = '?';
    if (tipo != null) query += 'tipo=$tipo&';
    if (ubicacion != null) query += 'ubicacion=$ubicacion&';
    if (nivel != null) query += 'nivel=$nivel&';

    final url = Uri.parse('$_baseUrl/buscar${query.isNotEmpty ? query : ''}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Alerta.fromJson(json)).toList();
    } else {
      throw Exception('Error al buscar alertas');
    }
  }

  // ✅ Marcar alerta como vista
  Future<bool> marcarComoVista(int id) async {
    final url = Uri.parse('$_baseUrl/$id/vista');
    final response = await http.put(url);

    return response.statusCode == 200;
  }
}
