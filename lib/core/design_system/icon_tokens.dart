import 'package:flutter/material.dart';

/// Sistema de Ícones Centralizado (IconTokens).
/// Nenhuma tela do aplicativo deve importar ícones do Material Symbols diretamente.
/// Tudo deve passar por esta classe para permitir troca global da biblioteca de ícones.
class IconTokens {
  // Módulos
  static const IconData lesson = Icons.menu_book_rounded;
  static const IconData games = Icons.extension_rounded;
  static const IconData parents = Icons.family_restroom_rounded;
  static const IconData ai = Icons.auto_awesome_rounded;
  static const IconData library = Icons.video_library_rounded;
  static const IconData students = Icons.people_rounded;

  // Ações de Navegação
  static const IconData home = Icons.home_rounded;
  static const IconData back = Icons.chevron_left_rounded;
  static const IconData forward = Icons.chevron_right_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData menu = Icons.menu_rounded;

  // Ações Gerais
  static const IconData play = Icons.play_arrow_rounded;
  static const IconData pause = Icons.pause_rounded;
  static const IconData stop = Icons.stop_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData add = Icons.add_rounded;
  static const IconData check = Icons.check_rounded;

  // Feedback e Status
  static const IconData success = Icons.check_circle_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData error = Icons.error_outline_rounded;
  static const IconData info = Icons.info_outline_rounded;
  
  // Gamificação e Estrelas
  static const IconData star = Icons.star_rounded;
  static const IconData starHalf = Icons.star_half_rounded;
  static const IconData starEmpty = Icons.star_border_rounded;
  static const IconData trophy = Icons.emoji_events_rounded;
  static const IconData medal = Icons.military_tech_rounded;
}
