import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/global_config.dart';

class AuthService {
  //IP
  final String _baseUrl = '${GlobalConfig.baseURL}/api';

  // 👉 Registro de usuarios desde el formulario normal
  Future<String?> register(String email, String password, String nombre) async {
    final url = Uri.parse('$_baseUrl/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'nombre': nombre,
          'role': 'usuario' // rol por defecto
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['message'].toString().toLowerCase().contains('usuario')) {
          return 'success';
        }
      }
      return data['message'] ?? 'error';
    } catch (e) {
      return 'network-error';
    }
  }

  // ✅ Obtener rol del usuario
  Future<String?> getUserRole(String uid) async {
    final url = Uri.parse('$_baseUrl/auth/role/$uid');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['rol'] ?? 'usuario';
      } else {
        return 'usuario';
      }
    } catch (e) {
      return 'usuario';
    }
  }

  // ✅ Obtener todos los usuarios
  Future<List<dynamic>?> fetchUsers() async {
    final url = Uri.parse('$_baseUrl/usuarios');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error al obtener usuarios: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error de red: $e');
      return null;
    }
  }

  // ✅ Actualizar rol de usuario
  Future<bool> updateUserRole(String userId, String newRole) async {
    final url = Uri.parse('$_baseUrl/usuarios/$userId');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'role': newRole}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error al actualizar rol: $e');
      return false;
    }
  }

  // ✅ Crear usuario desde la administración
  Future<bool> createUserAsAdmin(String email, String password, String nombre, String role) async {
    final url = Uri.parse('$_baseUrl/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'nombre': nombre,
          'role': role,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error al crear usuario: $e');
      return false;
    }
  }

  // ✅ Eliminar usuario por ID
  Future<bool> deleteUser(String userId) async {
    final url = Uri.parse('$_baseUrl/usuarios/$userId');
    try {
      final response = await http.delete(url);
      return response.statusCode == 200;
    } catch (e) {
      print('Error al eliminar usuario: $e');
      return false;
    }
  }
}
