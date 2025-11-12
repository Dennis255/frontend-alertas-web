import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/global_config.dart';

class ReporteService {
  //IP
  final String _baseUrl = '${GlobalConfig.baseURL}/api/reportes';

  // ✅ Obtener resumen por tipo y nivel
  Future<List<Map<String, dynamic>>> obtenerResumenAlertas() async {
    final url = Uri.parse('$_baseUrl/alertas/resumen');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        print('❌ Error al obtener resumen de alertas: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Excepción en obtenerResumenAlertas: $e');
      return [];
    }
  }
  Future<List<Map<String, dynamic>>> obtenerAlertasCompletas() async {
  final url = Uri.parse('${GlobalConfig.baseURL}/api/reportes/alertas/completo');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      print('❌ Error en respaldo completo: ${response.body}');
      return [];
    }
  } catch (e) {
    print('❌ Excepción al obtener respaldo: $e');
    return [];
  }
}


  // ✅ También debe estar este si usas ubicaciones
  Future<List<Map<String, dynamic>>> obtenerResumenPorUbicacion() async {
    final url = Uri.parse('$_baseUrl/alertas/ubicacion');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        print('❌ Error al obtener resumen por ubicación: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Excepción: $e');
      return [];
    }
  }
}
