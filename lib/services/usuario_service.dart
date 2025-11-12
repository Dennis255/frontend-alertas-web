import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/global_config.dart';

class UsuarioService {
  //IP
  final String _baseUrl = '${GlobalConfig.baseURL}/api/usuarios';

  Future<bool> cambiarRol({
    required String userId,
    required String nuevoRol,
    required String adminId,
  }) async {
    final url = Uri.parse('$_baseUrl/cambiar-rol/$userId');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nuevoRol': nuevoRol,
          'adminId': adminId,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('❌ Error al cambiar rol: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Excepción en cambiarRol: $e');
      return false;
    }
  }
}
