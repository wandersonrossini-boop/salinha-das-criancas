import 'package:shared_preferences/shared_preferences.dart';

/// Estado possível da aula de hoje, usado pelo Hero Card ("Hoje na Aula")
/// na Home para decidir texto, ícone e ação principal.
enum AulaStatus {
  /// Nenhum plano de aula (LessonPlan) foi gerado/salvo ainda.
  semPlano,

  /// Existe plano, mas a chamada de hoje ainda não foi feita.
  chamadaPendente,

  /// Chamada feita hoje, mas o Modo Ministrar ainda não foi aberto.
  aulaNaoIniciada,

  /// O professor já avançou por pelo menos uma etapa do Modo Ministrar hoje.
  aulaEmAndamento,

  /// A aula foi marcada como concluída (botão "Finalizar Ministração").
  aulaConcluida,
}

/// Resultado de [AulaStatusService.getStatus]: o status + a etapa atual
/// (quando aplicável), para o Hero Card mostrar "Etapa X de Y".
class AulaStatusResult {
  final AulaStatus status;
  final int etapaAtual; // 0-based
  final int totalEtapas;

  const AulaStatusResult({
    required this.status,
    this.etapaAtual = 0,
    this.totalEtapas = 5,
  });
}

/// Serviço responsável exclusivamente por ler e gravar o STATUS da aula
/// do dia (chamada feita? etapa atual? concluída?).
///
/// Contrato (ver ADR-001-AulaStatusService.md):
/// - GRAVA: data da chamada (reaproveitada de 'attendance_date'), etapa
///   atual do Modo Ministrar, data em que essa etapa foi salva.
/// - LÊ: também a flag 'lesson_completed_<id>' já gravada por
///   DatabaseHelper.markLessonAsCompleted, sem duplicar essa informação.
/// - NÃO GRAVA: alunos, LessonPlan, equipes, quiz, relatório. Para isso,
///   use os serviços/DatabaseHelper já existentes.
class AulaStatusService {
  static const _kAttendanceDateKey = 'attendance_date';
  static const _kEtapaKeyPrefix = 'etapa_atual_'; // + lessonId
  static const _kEtapaDataSuffix = '_data'; // + lessonId + _data

  static String _hoje() => DateTime.now().toIso8601String().split('T')[0];

  /// Consulta o status atual da aula referente a [lessonId].
  /// [totalEtapas] é passado pela tela que já monta a lista `_etapas`
  /// (Modo Ministrar), para não duplicar essa contagem aqui.
  static Future<AulaStatusResult> getStatus({
    required int? lessonId,
    int totalEtapas = 5,
  }) async {
    if (lessonId == null) {
      return AulaStatusResult(status: AulaStatus.semPlano, totalEtapas: totalEtapas);
    }

    final prefs = await SharedPreferences.getInstance();
    final hoje = _hoje();

    // 1. Aula já concluída? (flag já gravada por DatabaseHelper.markLessonAsCompleted)
    final concluida = prefs.getBool('lesson_completed_$lessonId') ?? false;
    if (concluida) {
      return AulaStatusResult(
        status: AulaStatus.aulaConcluida,
        etapaAtual: totalEtapas - 1,
        totalEtapas: totalEtapas,
      );
    }

    // 2. Chamada foi feita hoje? (reaproveita 'attendance_date' já existente)
    final attendanceDate = prefs.getString(_kAttendanceDateKey) ?? '';
    final chamadaFeitaHoje = attendanceDate == hoje;
    if (!chamadaFeitaHoje) {
      return AulaStatusResult(status: AulaStatus.chamadaPendente, totalEtapas: totalEtapas);
    }

    // 3. Existe etapa salva para hoje?
    final etapaKey = '$_kEtapaKeyPrefix$lessonId';
    final dataEtapaKey = '$etapaKey$_kEtapaDataSuffix';
    final dataEtapaSalva = prefs.getString(dataEtapaKey) ?? '';
    final etapaSalva = prefs.getInt(etapaKey);

    if (etapaSalva == null || dataEtapaSalva != hoje) {
      return AulaStatusResult(status: AulaStatus.aulaNaoIniciada, totalEtapas: totalEtapas);
    }

    return AulaStatusResult(
      status: AulaStatus.aulaEmAndamento,
      etapaAtual: etapaSalva,
      totalEtapas: totalEtapas,
    );
  }

  /// Chamado pelo ClassModeScreen (`_navigateToStep`) sempre que o
  /// professor avança para uma nova etapa hoje.
  static Future<void> salvarEtapaAtual({
    required int lessonId,
    required int etapaIndex,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final etapaKey = '$_kEtapaKeyPrefix$lessonId';
    await prefs.setInt(etapaKey, etapaIndex);
    await prefs.setString('$etapaKey$_kEtapaDataSuffix', _hoje());
  }
}
