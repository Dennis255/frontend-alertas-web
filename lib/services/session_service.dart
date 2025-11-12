import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  // Guardar los datos del usuario
  static Future<void> saveUserSession({
    required String id,
    required String nombre,
    required String rol,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', id);
    await prefs.setString('nombre', nombre);
    await prefs.setString('rol', rol);
  }

  // Verificar si está logueado
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Obtener rol
  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('rol') ?? '';
  }

  // Obtener nombre
  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nombre') ?? '';
  }

  // Cerrar sesión
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
