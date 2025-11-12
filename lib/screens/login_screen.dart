import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/session_service.dart';
import '../config/global_config.dart';
import '../services/alert_notifier_service.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
  
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final response = await _authenticateUser(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (response != null && response['status'] == 'success') {
      final user = response['user'];
      final String rol = user['role'];

      await SessionService.saveUserSession(
        id: user['id'].toString(),
        nombre: user['nombre'],
        rol: rol,
      );

 final alertService = AlertNotifierService();
  alertService.iniciarVerificacionPeriodica(segundos: 3);
      _showSuccessMessage('Inicio de sesión exitoso');
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      final error = response?['message'] ?? 'Credenciales incorrectas';
      _showErrorMessage(error);
    }
  }

  Future<Map<String, dynamic>?> _authenticateUser(String email, String password) async {
    const url = '${GlobalConfig.baseURL}/api/auth/login';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        return {'status': 'error', 'message': 'Credenciales inválidas'};
      } else {
        return {'status': 'error', 'message': 'Error del servidor'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Error de conexión'};
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _irARegistro() {
    Navigator.pushNamed(context, '/register');
  }

  void _irARecuperarPassword() {
    Navigator.pushNamed(context, '/recover');
  }

  void _irAAlertasPublicas() {
    Navigator.pushNamed(context, '/public');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    // Obtenemos la altura del viewport para usarla en el ConstrainedBox
    final screenHeight = size.height;

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFBBDEFB),
              Color(0xFF90CAF9),
            ],
          ),
        ),
        // 1. SingleChildScrollView HACE QUE TODA LA PANTALLA SEA DESLIZABLE
        child: SingleChildScrollView(
          child: ConstrainedBox(
            // 2. Forza al contenido a tener AL MENOS la altura de la pantalla
            constraints: BoxConstraints(
              minHeight: screenHeight, 
            ),
            child: SafeArea(
              child: Column(
                // 3. Distribuye el espacio: pone el header arriba, 
                //    el footer abajo, y el login en medio.
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  
                  // ============= ENCABEZADO (Header) =============
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Image.asset(
                          'assets/UNACH.png',
                          height: 60,
                          errorBuilder: (c, e, s) => const Icon(Icons.school, color: Colors.blueGrey),
                        ),
                        const SizedBox(width: 12),
                        Image.asset(
                          'assets/TI.png',
                          height: 60,
                          errorBuilder: (c, e, s) => const Icon(Icons.code, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),

                  // ============= CONTENIDO (Tarjeta de Login) =============
                  // Ya no está dentro de un 'Expanded', es solo un hijo más
                  Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), // Margen vertical
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    // Tu Formulario (sin cambios internos)
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            children: [
                              Image.asset('assets/images/logo.png', height: 100, width: 100),
                              const SizedBox(height: 24),
                              Text(
                                "Inicio de Sesión",
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1976D2),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Ingrese sus credenciales para continuar",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.blueGrey[600],
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Correo Electrónico",
                              labelStyle: const TextStyle(color: Colors.blueGrey),
                              prefixIcon: const Icon(Icons.email_outlined, color: Colors.blueGrey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.blueGrey),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.blueGrey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Ingrese su correo electrónico';
                              if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,4}$').hasMatch(value)) return 'Correo inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: "Contraseña",
                              labelStyle: const TextStyle(color: Colors.blueGrey),
                              prefixIcon: const Icon(Icons.lock_outlined, color: Colors.blueGrey),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.blueGrey,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.blueGrey),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.blueGrey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Ingrese su contraseña' : null,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _irARecuperarPassword,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                "¿Olvidó su contraseña?",
                                style: TextStyle(
                                  color: Color(0xFF1976D2),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Text(
                                    "INICIAR SESIÓN",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: TextButton(
                              onPressed: _irARegistro,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: RichText(
                                text: TextSpan(
                                  text: "¿No tiene una cuenta? ",
                                  style: TextStyle(color: Colors.blueGrey[600]),
                                  children: const [
                                    TextSpan(
                                      text: "Regístrese",
                                      style: TextStyle(
                                        color: Color(0xFF1976D2),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton.icon(
                              onPressed: _irAAlertasPublicas,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.public, color: Color(0xFF1976D2), size: 18),
                              label: const Text(
                                "Ver alertas sin iniciar sesión",
                                style: TextStyle(
                                  color: Color(0xFF1976D2),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ============= PIE DE PÁGINA (Footer) =============
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    width: double.infinity,
                    child: Image.asset(
                      'assets/SEAP.png',
                      fit: BoxFit.fitWidth,
                      errorBuilder: (c, e, s) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}