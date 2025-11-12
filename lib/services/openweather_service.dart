import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenWeatherService {
  static const String _apiKey = 'fcbd3d67b7b75489486709e579a99d03';
  static const double lat = -2.4031;
  static const double lon = -78.7964;

  static Future<Map<String, dynamic>> obtenerDatos() async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$_apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'temperatura': data['main']['temp'],
        'humedad': data['main']['humidity'],
        'viento': (data['wind']['speed'] * 3.6).toStringAsFixed(1), // km/h
      };
    } else {
      throw Exception('Error al obtener datos del clima');
    }
  }
}
