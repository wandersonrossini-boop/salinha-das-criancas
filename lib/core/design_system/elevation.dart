import 'package:flutter/material.dart';

class DsElevation {
  // Float Cards Style (Premium Glassmorphism)
  static List<BoxShadow> get floatCard => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.08),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.02),
          blurRadius: 8,
          spreadRadius: -2,
          offset: const Offset(0, 4),
        ),
      ];

  // Glow para Botões
  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];
      
  // Elevação sutil para elementos menores (Badges, Avatares)
  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}
