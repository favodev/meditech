import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/two_factor_screen.dart';
import 'screens/setup_2fa_screen.dart';
import 'screens/two_factor_methods_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/compartir_informe_screen.dart';
import 'screens/configuracion_screen.dart';
import 'screens/estadisticas_screen.dart';
import 'screens/informes_screen.dart';
import 'screens/permisos_compartidos_screen.dart';
import 'screens/qr_scanner_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediTech',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/two-factor') {
          final args = settings.arguments as Map<String, dynamic>?;
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) =>
                TwoFactorScreen(tempToken: args?['tempToken'] ?? ''),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          );
        }

        if (settings.name == '/reset-password') {
          final args = settings.arguments as Map<String, dynamic>?;
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) =>
                ResetPasswordScreen(email: args?['email'] ?? ''),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          );
        }

        // Nuevas rutas con argumentos
        if (settings.name == '/compartir-informe') {
          final args = settings.arguments as Map<String, dynamic>;
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) =>
                CompartirInformeScreen(informe: args),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          );
        }

        if (settings.name == '/informes') {
          final args = settings.arguments as Map<String, dynamic>?;
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) =>
                InformesScreen(initialFilter: args?['filter']),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          );
        }

        final routes = <String, WidgetBuilder>{
          '/': (context) => const SplashScreen(),
          '/home': (context) => const MainScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/change-password': (context) => const ChangePasswordScreen(),
          '/2fa-methods': (context) => const TwoFactorMethodsScreen(),
          '/setup-2fa': (context) => const Setup2FAScreen(),
          '/configuracion': (context) => const ConfiguracionScreen(),
          '/estadisticas': (context) => const EstadisticasScreen(),
          '/permisos-compartidos': (context) =>
              const PermisosCompartidosScreen(),
          '/qr-scanner': (context) => const QRScannerScreen(),
        };

        final builder = routes[settings.name];
        if (builder != null) {
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) =>
                builder(context),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          );
        }
        return null;
      },
    );
  }
}
