import 'package:flutter/material.dart';

class NotificadorGlobal {
  static final NotificadorGlobal _instancia = NotificadorGlobal._interno();
  factory NotificadorGlobal() => _instancia;
  NotificadorGlobal._interno();

  OverlayEntry? _entrada;

  void mostrar({
    required BuildContext context,
    required String mensaje,
    IconData icono = Icons.info_outline,
    Color fondo = Colors.orange,
    Color texto = Colors.white,
    Duration duracion = const Duration(seconds: 5),
  }) {
    cerrar(); // cierra si ya hay uno

    _entrada = OverlayEntry(
      builder: (_) => Positioned(
        top: 40,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Icon(icono, color: texto),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    mensaje,
                    style: TextStyle(color: texto, fontSize: 14),
                  ),
                ),
                GestureDetector(
                  onTap: cerrar,
                  child: Icon(Icons.close, color: texto),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_entrada!);

    Future.delayed(duracion, cerrar);
  }

  void cerrar() {
    _entrada?.remove();
    _entrada = null;
  }
}
