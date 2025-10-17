import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediTech',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      // ✅ Usa onGenerateRoute para transiciones personalizadas
      onGenerateRoute: (settings) {
        // Mapeo de rutas a widgets

        final routes = <String, WidgetBuilder>{
          '/': (context) => const SplashScreen(),
          '/home': (context) => const MainScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(), // Nueva ruta
        };

        final builder = routes[settings.name];
        if (builder != null) {
          // ✅ Transición personalizada para TODAS las rutas
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
