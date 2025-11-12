import 'package:flutter/material.dart';

class NotificacionBanner extends StatelessWidget {
  final String mensaje;
  final IconData icono;
  final Color fondo;
  final Color textoColor;
  final VoidCallback onClose;

  const NotificacionBanner({
    super.key,
    required this.mensaje,
    required this.icono,
    required this.fondo,
    this.textoColor = Colors.white,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icono, color: textoColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(color: textoColor, fontSize: 14),
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close, color: textoColor),
            ),
          ],
        ),
      ),
    );
  }
}
