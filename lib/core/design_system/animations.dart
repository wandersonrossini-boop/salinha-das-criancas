import 'package:flutter/material.dart';

class DsAnimations {
  // Durações
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  // Motion Durations (Motion Design Premium)
  static const Duration fadeDuration = Duration(milliseconds: 300);
  static const Duration slideDuration = Duration(milliseconds: 400);
  static const Duration heroDuration = Duration(milliseconds: 500);
  static const Duration scaleDuration = Duration(milliseconds: 300);
  static const Duration bounceDuration = Duration(milliseconds: 600);
  static const Duration confettiDuration = Duration(milliseconds: 1500);
  static const Duration rippleDuration = Duration(milliseconds: 400);
  static const Duration pulseDuration = Duration(milliseconds: 1000);
  static const Duration pageTransitionDuration = Duration(milliseconds: 400);

  // Curves (Motion Design Premium)
  static const Curve smooth = Curves.easeOutCubic;
  static const Curve bouncy = Curves.elasticOut;
  static const Curve decelerate = Curves.easeOutQuart;

  static const Curve fadeCurve = Curves.easeIn;
  static const Curve slideCurve = Curves.easeOutCubic;
  static const Curve heroCurve = Curves.fastOutSlowIn;
  static const Curve scaleCurve = Curves.easeOutBack;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve confettiCurve = Curves.easeOut;
  static const Curve rippleCurve = Curves.easeOut;
  static const Curve pulseCurve = Curves.easeInOutSine;
  static const Curve pageTransitionCurve = Curves.easeInOutCubic;
}
