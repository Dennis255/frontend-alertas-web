import 'package:flutter/material.dart';
import 'services/session_service.dart';
import 'services/alert_notifier_service.dart'; // ✅ Servicio global para alertas

// Screens
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/alertas_screen.dart';
import 'screens/crear_alerta_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/bienvenida_screen.dart';
import 'screens/error_404_screen.dart';
import 'screens/reportes_screen.dart';
import 'screens/reportes_ubicacion_screen.dart';
import 'screens/monitoreo_log_screen.dart';
import 'screens/resumen_alertas_graficas_screen.dart';
import 'screens/alertas_ubicacion_screen.dart';
import 'screens/mapa_alertas_screen.dart';
import 'screens/tabla_alertas_screen.dart';
import 'screens/public_home_screen.dart';
import 'screens/estadisticas_fuentes_screen.dart';
import 'screens/estadisticas_evolucion_screen.dart';
import 'screens/public_alerta_detalle_screen.dart';
import 'screens/evolucion_lineas_screen.dart';
import 'screens/umbrales_screen.dart';

// 🔑 Clave global de navegación
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Inicializar el servicio de alertas ANTES de cualquier sesión
  AlertNotifierService().setNavigatorKey(navigatorKey);
  AlertNotifierService().iniciarVerificacionPeriodica(); // siempre activo

  // 🔐 Verifica si hay sesión activa
  final isLoggedIn = await SessionService.isLoggedIn();

  // ✅ Si no hay sesión, va al modo público
  runApp(MyApp(initialRoute: isLoggedIn ? '/dashboard' : '/bienvenida'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ Necesario para las alertas globales
      debugShowCheckedModeBanner: false,
      title: 'Alerta Temprana',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3366CC),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/bienvenida': (context) => const BienvenidaScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/alertas': (context) => const AlertasScreen(),
        '/crear-alerta': (context) => const CrearAlertaScreen(),
        '/admin': (context) => const AdminScreen(adminId: '1'),
        '/perfil': (context) => const PerfilScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/reportes': (context) => const ReportesScreen(),
        '/reportes-ubicacion': (context) => const ReportesUbicacionScreen(),
        '/monitoreo': (context) => const MonitoreoLogScreen(),
        '/graficas-alertas': (context) => const ResumenAlertasGraficas(),
        '/alertas-ubicacion': (context) => AlertasUbicacionScreen(ubicacion: ''),
        '/tabla-alertas': (context) => const TablaAlertasScreen(),
        '/public': (context) => const PublicHomeScreen(),
        '/estadisticas-fuentes': (context) => const EstadisticasFuentesScreen(),
        '/estadisticas-evolucion': (context) => const EstadisticasEvolucionScreen(),
        '/evolucion-lineas': (context) => const EvolucionLineasScreen(),
        '/umbrales': (context) => const UmbralesScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/mapa-alertas') {
          final String ubicacion = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => MapaAlertasScreen(ubicacion: ubicacion),
          );
        }

        if (settings.name == '/public-alerta-detalle') {
          final Map alerta = settings.arguments as Map;
          return MaterialPageRoute(
            builder: (_) => PublicAlertaDetalleScreen(alerta: alerta),
          );
        }

        // Página por defecto si la ruta no existe
        return MaterialPageRoute(
          builder: (_) => const Error404Screen(),
        );
      },
    );
  }
}
