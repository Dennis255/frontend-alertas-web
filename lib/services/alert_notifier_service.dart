import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../config/global_config.dart';

class AlertNotifierService {
  static final AlertNotifierService _instance = AlertNotifierService._internal();
  factory AlertNotifierService() => _instance;
  AlertNotifierService._internal();
    String? _ultimaAlertaId;
  int _contadorHeladas = 0;

  bool _puedeReproducirSonido(dynamic alerta) {
    final tipo = alerta['tipo']?.toString().toLowerCase() ?? '';
    final id = alerta['id']?.toString() ?? '';
    final horaActual = DateTime.now().hour;

if (horaActual == 6) {
  _contadorHeladas = 0;
  _ultimaAlertaId = null;
}

    if (tipo.contains('helada') && (horaActual >= 19 || horaActual < 6)) {
      if (_ultimaAlertaId == id) {
        _contadorHeladas++;
        if (_contadorHeladas > 3) {
          return false; // ❌ Ya se notificó 3 veces esta alerta de helada
        }
      } else {
        _ultimaAlertaId = id;
        _contadorHeladas = 1;
      }
    } else {
      // Si es otro tipo de alerta o antes de las 7 PM, reinicia contador
      _contadorHeladas = 0;
      _ultimaAlertaId = null;
    }

    return true;
  }


  final AudioPlayer _audioPlayer = AudioPlayer();
  List<dynamic> _alertasAnteriores = [];
  Timer? _timer;
  GlobalKey<NavigatorState>? _navigatorKey;
  bool _mostrandoAlerta = false;

  final Color _colorAlerta = const Color(0xFFD32F2F);
  final Color _colorFondo = const Color(0xFFF5F5F5);
  final Color _colorTexto = const Color(0xFF333333);
  final Color _colorBoton = const Color(0xFF1976D2);

  /// Asigna la navigatorKey global desde main.dart
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Inicia la verificación periódica
  void iniciarVerificacionPeriodica({int segundos = 3}) async {
    await _cargarAlertasIniciales();
    _verificarAlertas();
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: segundos), (_) => _verificarAlertas());
    debugPrint('✅ Verificación periódica iniciada cada $segundos segundos');
  }

  Future<void> _cargarAlertasIniciales() async {
    try {
      final res = await http.get(Uri.parse('${GlobalConfig.baseURL}/api/alertas')); // Asegúrate de que esta IP es la correcta
      if (res.statusCode == 200) {
        _alertasAnteriores = jsonDecode(res.body);
        debugPrint('📦 Alertas iniciales cargadas: ${_alertasAnteriores.length}');
      }
    } catch (e) {
      debugPrint('⚠️ No se pudieron cargar alertas iniciales: $e');
    }
  }

  void detenerVerificacion() {
    _timer?.cancel();
    debugPrint('⛔ Verificación de alertas detenida');
  }

  Future<void> _verificarAlertas() async {
    try {
      final response = await http.get(Uri.parse('${GlobalConfig.baseURL}/api/alertas'));

      if (response.statusCode == 200) {
        final List<dynamic> nuevasAlertas = jsonDecode(response.body);

        if (_esAlertaNueva(nuevasAlertas)) {
  debugPrint('🚨 Nueva alerta detectada');

  final nuevaAlerta = nuevasAlertas.last;
  final tipo = nuevaAlerta['tipo']?.toString().toLowerCase() ?? '';

  if (_puedeReproducirSonido(nuevaAlerta)) {
    await _reproducirSonido();
  } else {
    debugPrint('🔕 Sonido silenciado por exceso de heladas consecutivas en la noche');
  }

  _cambiarTituloTemporal('🚨 ALERTA DETECTADA 🚨');
  _mostrarSnackbar();
  if (!_mostrandoAlerta) {
    _mostrarDialogoAlerta();
  }
  _alertasAnteriores = List.from(nuevasAlertas);

}


        _alertasAnteriores = nuevasAlertas;
      } else {
        debugPrint('⚠️ Error al obtener alertas: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error durante la verificación: $e');
    }
  }

  bool _esAlertaNueva(List<dynamic> nuevas) {
    if (_alertasAnteriores.isEmpty) return nuevas.isNotEmpty;
    final anterioresIds = _alertasAnteriores.map((a) => a['id']).toSet();
    final nuevasIds = nuevas.map((a) => a['id']).toSet();
    return !anterioresIds.containsAll(nuevasIds);
  }

  void _cambiarTituloTemporal(String nuevoTitulo) {
    html.document.title = nuevoTitulo;
    Future.delayed(const Duration(seconds: 5), () {
      html.document.title = '🌤️ Sistema de Alertas Tempranas';
    });
  }

  Future<void> _reproducirSonido() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
    } catch (e) {
      debugPrint('🎵 Error al reproducir sonido: $e');
    }
  }

  void _mostrarSnackbar() {
    final context = _navigatorKey?.currentContext;
    if (context != null && !_mostrandoAlerta) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Nueva alerta detectada en el sistema',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: _colorAlerta,
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          action: SnackBarAction(
            label: 'Ver',
            textColor: Colors.white,
            onPressed: () {
              _navigatorKey?.currentState?.pushNamed('/alertas');
            },
          ),
        ),
      );
    }
  }

  void _mostrarDialogoAlerta() {
    final context = _navigatorKey?.currentContext;
    if (context != null && !_mostrandoAlerta) {
      _mostrandoAlerta = true;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return AlertDialog(
            backgroundColor: _colorFondo,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _colorAlerta.withOpacity(0.9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
                  SizedBox(width: 12),
                  Text(
                    'ALERTA DETECTADA',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notification_important, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Se ha registrado una nueva alerta en el sistema.\n\nRevise el módulo de alertas para más detalles.',
                  style: TextStyle(color: _colorTexto, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _colorTexto,
                  side: BorderSide(color: _colorTexto.withOpacity(0.3)),
                ),
                onPressed: () {
                  _mostrandoAlerta = false;
                  Navigator.of(context).pop();
                },
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _colorBoton,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  _mostrandoAlerta = false;
                  Navigator.of(context).pop();
                  _navigatorKey?.currentState?.pushNamed('/alertas');
                },
                child: const Text('Ver alertas'),
              ),
            ],
          );
        },
      ).then((_) {
        _mostrandoAlerta = false;
      });
    }
  }
}
