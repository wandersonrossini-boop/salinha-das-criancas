import 'package:flutter/material.dart';

enum HeroActionType {
  startAttendance,
  startClass,
  continueClass,
}

class HeroActionCard extends StatelessWidget {
  final String title;
  final String verse;
  final String badgeText;
  final Color badgeColor;
  final HeroActionType actionType;
  final VoidCallback onActionPressed;

  const HeroActionCard({
    super.key,
    required this.title,
    required this.verse,
    required this.badgeText,
    required this.badgeColor,
    required this.actionType,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final String buttonText = switch (actionType) {
      HeroActionType.startAttendance => 'Fazer Chamada da Turma',
      HeroActionType.startClass => 'Iniciar Aula de Hoje',
      HeroActionType.continueClass => 'Continuar Aula',
    };

    final IconData buttonIcon = switch (actionType) {
      HeroActionType.startAttendance => Icons.fact_check_outlined,
      HeroActionType.startClass => Icons.play_arrow_rounded,
      HeroActionType.continueClass => Icons.arrow_forward_rounded,
    };

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge Temporal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Título e Versículo Unificados
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.bookmark_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Versículo: $verse',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ÚNICO Botão de Ação Primária
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onActionPressed,
                icon: Icon(buttonIcon),
                label: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
