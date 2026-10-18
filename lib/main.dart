import 'package:flutter/material.dart';
import 'core/design_system/theme.dart';
import 'features/home/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/auth/screens/login_screen.dart';

import 'package:flutter_web_plugins/url_strategy.dart';

import 'dart:async';
import 'dart:ui';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    usePathUrlStrategy();

    // Captura erros do framework Flutter (build, layout, painting)
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('=== FlutterError capturado ===');
      debugPrint(details.exceptionAsString());
      debugPrint(details.stack?.toString() ?? 'sem stack');
    };

    // Captura erros assíncronos não tratados (TypeErrors, etc.)
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('=== PlatformDispatcher error capturado ===');
      debugPrint('$error');
      debugPrint('$stack');
      return true; // Marca como tratado (não propaga)
    };

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Erro ao inicializar Firebase (possível chave ausente): $e');
    }
    runApp(const SalinhaApp());
  }, (error, stack) {
    debugPrint('=== Zone error capturado ===');
    debugPrint('$error');
    debugPrint('$stack');
  });
}

class SalinhaApp extends StatelessWidget {
  const SalinhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: 'Salinha das Crianças',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const LoginScreen(),
    );

    return Container(
      color: const Color(0xFF0F172A), // Fundo azul escuro para Desktop/Web
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ClipRect(
            child: app,
          ),
        ),
      ),
    );
  }
}
