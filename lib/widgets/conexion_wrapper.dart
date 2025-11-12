import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../screens/sin_conexion_screen.dart';

class ConexionWrapper extends StatefulWidget {
  final Widget child;

  const ConexionWrapper({super.key, required this.child});

  @override
  State<ConexionWrapper> createState() => _ConexionWrapperState();
}

class _ConexionWrapperState extends State<ConexionWrapper> {
  late final Connectivity _connectivity;
  late final ConnectivityResult _initialStatus;
  late final Stream<ConnectivityResult> _connectivityStream;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;
    verificarConexionInicial();
  }

  Future<void> verificarConexionInicial() async {
    final result = await _connectivity.checkConnectivity();
    if (result == ConnectivityResult.none && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SinConexionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
      stream: _connectivityStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == ConnectivityResult.none) {
          return const SinConexionScreen();
        }
        return widget.child;
      },
    );
  }
}
