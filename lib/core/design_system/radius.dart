import 'package:flutter/material.dart';

class DsRadius {
  // Cantos arredondados amigáveis (Padrão Apple HI / Material 3)
  static const BorderRadius small = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius large = BorderRadius.all(Radius.circular(24.0));
  static const BorderRadius xlarge = BorderRadius.all(Radius.circular(28.0));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999.0));

  // Apenas o valor (útil para decorações mais complexas)
  static const double vSmall = 12.0;
  static const double vMedium = 16.0;
  static const double vLarge = 24.0;
  static const double vXlarge = 28.0;
}
