import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/design_system/colors.dart';
import '../../../core/db/database_helper.dart';
import '../../../core/services/aula_status_service.dart';
import '../../ai_planner/models/lesson_plan.dart';
import '../../games/screens/quiz_screen.dart';
import '../../games/screens/games_menu_screen.dart';
import '../../roulette/screens/roulette_screen.dart';
import '../../students/screens/chamada_screen.dart';
import '../../students/models/student.dart';
import '../../teams/screens/teams_screen.dart';

class ClassModeScreen extends StatefulWidget {
  const ClassModeScreen({super.key});

  @override
  State<ClassModeScreen> createState() => _ClassModeScreenState();
}

class _ClassModeScreenState extends State<ClassModeScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isLoading = true;
  LessonPlan? _currentPlan;
  List<Map<String, dynamic>> _quizQuestions = [];

  List<Map<String, dynamic>> _etapas = [];

  int _expandedIndex = 0;
  final Map<int, GlobalKey> _cardKeys = {};
  final Map<int, ExpansionTileController> _controllers = {};

  List<Student> _groupA = [];
  List<Student> _groupB = [];
  bool _hasDividedGroups = false;

  Future<bool> _isCompletedToday() async {
    if (_currentPlan?.id == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final hoje = DateTime.now().toIso8601String().split('T')[0];
    final concluida = prefs.getBool('lesson_completed_${_currentPlan!.id}') ?? false;
    final concluidaData = prefs.getString('lesson_completed_${_currentPlan!.id}_data') ?? '';
    return concluida && (concluidaData.isEmpty || concluidaData == hoje);
  }

  Future<void> _ensureGroupsLoaded() async {
    if (_hasDividedGroups && (_groupA.isNotEmpty || _groupB.isNotEmpty)) return;

    final students = await DatabaseHelper.instance.fetchAllStudents();
    final prefs = await SharedPreferences.getInstance();
    final presentIds = prefs.getStringList('present_student_ids') ?? [];

    final presentStudents = students.where((s) => presentIds.contains(s.id.toString())).toList();
    if (presentStudents.isEmpty) {
      presentStudents.addAll(students);
    }

    final half = (presentStudents.length / 2).ceil();
    _groupA = presentStudents.take(half).toList();
    _groupB = presentStudents.skip(half).toList();
    _hasDividedGroups = true;
  }

  Future<void> _finishLessonAndShowReport() async {
    try {
      if (_currentPlan != null) {
        await DatabaseHelper.instance.markLessonAsCompleted(
          _currentPlan!.id,
          themeTitle: _currentPlan!.title,
        );
      }
    } catch (dbError) {
      debugPrint('Erro ao atualizar banco: $dbError');
    }

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final teacherName = prefs.getString('current_teacher_name') ?? 'Professor';
    final startedAtStr = prefs.getString('lesson_started_at_${_currentPlan?.id}');
    final endedAt = DateTime.now();
    DateTime startedAt = startedAtStr != null ? DateTime.parse(startedAtStr) : endedAt.subtract(const Duration(minutes: 45));
    int durationMinutes = endedAt.difference(startedAt).inMinutes;
    if (durationMinutes <= 0) durationMinutes = 45;

    final allStudents = await DatabaseHelper.instance.fetchAllStudents();
    List<String> presentIds = prefs.getStringList('present_student_ids') ?? [];
    if (presentIds.isEmpty) {
      final attendanceList = await DatabaseHelper.instance.fetchAllAttendance();
      if (attendanceList.isNotEmpty) {
        final latest = attendanceList.first;
        final idsStr = (latest['student_ids'] as String?) ?? '';
        if (idsStr.isNotEmpty) {
          presentIds = idsStr.split(',').where((e) => e.trim().isNotEmpty).toList();
        }
      }
    }
    final presentCount = presentIds.length;
    final totalStudents = allStudents.length;
    final absentCount = (totalStudents - presentCount).clamp(0, totalStudents);

    _showSessionReportModal(
      themeTitle: _currentPlan?.title ?? 'Aula de Hoje',
      teacherName: teacherName,
      durationMinutes: durationMinutes,
      presentCount: presentCount,
      absentCount: absentCount,
      totalStudents: totalStudents,
    );
  }

  void _showSessionReportModal({
    required String themeTitle,
    required String teacherName,
    required int durationMinutes,
    required int presentCount,
    required int absentCount,
    required int totalStudents,
    int totalPoints = 40,
  }) {
    final now = DateTime.now();
    final dateStr = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
    final ageGroup = _currentPlan?.ageGroup.isNotEmpty == true ? _currentPlan!.ageGroup : 'Juniores (7-9 anos)';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text('📊', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Relatório da Sessão',
                            style: TextStyle(fontFamily: 'Fredoka', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'Data: $dateStr • $ageGroup',
                            style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tema da Aula', style: TextStyle(fontFamily: 'Nunito', color: Color(0xFF64748B), fontSize: 13)),
                  trailing: Text(themeTitle, style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Professor Responsável', style: TextStyle(fontFamily: 'Nunito', color: Color(0xFF64748B), fontSize: 13)),
                  trailing: Text(teacherName, style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                ),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Duração Real', style: TextStyle(fontFamily: 'Nunito', color: Color(0xFF64748B), fontSize: 13)),
                        trailing: Text('$durationMinutes min', style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2563EB))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Pontuação Total', style: TextStyle(fontFamily: 'Nunito', color: Color(0xFF64748B), fontSize: 13)),
                        trailing: Text('🎯 $totalPoints pts', style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFD97706))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('PRESENTES', style: TextStyle(fontFamily: 'Fredoka', fontSize: 10, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text('$presentCount', style: const TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('AUSENTES', style: TextStyle(fontFamily: 'Fredoka', fontSize: 10, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text('$absentCount', style: const TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('TOTAL TURMA', style: TextStyle(fontFamily: 'Fredoka', fontSize: 10, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text('$totalStudents', style: const TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Atividades Realizadas na Ministração',
                  style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                          SizedBox(width: 8),
                          Text('Recepção e Chamada da Turma', style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                          SizedBox(width: 8),
                          Text('História Bíblica e Aplicação', style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                          SizedBox(width: 8),
                          Text('Quiz de Fixação e Dinâmica', style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                          SizedBox(width: 8),
                          Text('Oração de Encerramento e Apelo', style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  },
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Voltar ao Início', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DsColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollaborativeGroupsWidget() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.purple.shade50.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.purple.shade100, width: 1),
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: AppColors.roxoAcolhedor,
          collapsedIconColor: AppColors.roxoAcolhedor,
          title: const Row(
            children: [
              Icon(Icons.groups_rounded, color: AppColors.roxoAcolhedor, size: 18),
              SizedBox(width: 8),
              Text(
                'Visualizar Grupos da Atividade',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          children: [
            FutureBuilder<void>(
              future: _ensureGroupsLoaded(),
              builder: (context, snapshot) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Grupo A 🔵', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF))),
                            const SizedBox(height: 6),
                            if (_groupA.isEmpty)
                              const Text('Nenhum aluno', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Colors.grey))
                            else
                              ..._groupA.map((s) => Text('• ${s.name}', style: const TextStyle(fontFamily: 'Nunito', fontSize: 12.5, color: Color(0xFF1E293B)))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Grupo B 🟡', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB45309))),
                            const SizedBox(height: 6),
                            if (_groupB.isEmpty)
                              const Text('Nenhum aluno', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Colors.grey))
                            else
                              ..._groupB.map((s) => Text('• ${s.name}', style: const TextStyle(fontFamily: 'Nunito', fontSize: 12.5, color: Color(0xFF1E293B)))),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  ExpansionTileController _getController(int index) {
    return _controllers.putIfAbsent(index, () => ExpansionTileController());
  }

  GlobalKey _getCardKey(int index) {
    return _cardKeys.putIfAbsent(index, () => GlobalKey());
  }

  void _navigateToStep(int newIndex) {
    _getController(_expandedIndex).collapse();

    setState(() {
      _expandedIndex = newIndex;
    });

    _getController(newIndex).expand();

    // Persiste a etapa atual para a Home poder mostrar "Continuar Aula"
    // caso o professor saia e volte ao Modo Ministrar no mesmo dia.
    if (_currentPlan?.id != null) {
      AulaStatusService.salvarEtapaAtual(
        lessonId: _currentPlan!.id!,
        etapaIndex: newIndex,
      );
    }

    // Aguarda a animação do ExpansionTile/Accordion concluir antes de rolar
    Future.delayed(const Duration(milliseconds: 250), () {
      final context = _getCardKey(newIndex).currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.05, // Coloca o topo do card levemente abaixo do topo da tela
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadLatestPlan();
  }

  Future<void> _loadLatestPlan() async {
    final plans = await DatabaseHelper.instance.fetchAllLessonPlans();
    if (plans.isNotEmpty) {
      _currentPlan = plans.first;
      _buildEtapas(_currentPlan!);
      if (_currentPlan!.id != null) {
        // Registra o horário de início da aula se ainda não gravado no dia
        final prefs = await SharedPreferences.getInstance();
        final startedKey = 'lesson_started_at_${_currentPlan!.id}';
        if (!prefs.containsKey(startedKey)) {
          await prefs.setString(startedKey, DateTime.now().toIso8601String());
        }
        if (_currentPlan!.title.isNotEmpty) {
          await prefs.setString('current_lesson_theme_${_currentPlan!.id}', _currentPlan!.title);
        }

        // Ao abrir o Modo Ministrar, já registra "etapa 0" para a Home
        // deixar de mostrar "Iniciar Aula" e passar a mostrar "Continuar Aula".
        AulaStatusService.salvarEtapaAtual(
          lessonId: _currentPlan!.id!,
          etapaIndex: 0,
        );
      }
    } else {
      // Fallback
      _buildEtapasFallback();
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _buildEtapas(LessonPlan plan) {
    String questionsDisplay = plan.questions;
    _quizQuestions = [];

    try {
      final decoded = jsonDecode(plan.questions);
      if (decoded is List) {
        _quizQuestions = List<Map<String, dynamic>>.from(decoded.map((x) => Map<String, dynamic>.from(x)));
        questionsDisplay = _quizQuestions.map((q) => '${q['question']}\nResposta: ${q['answer']}').join('\n\n');
      }
    } catch (_) {
      // Ignora erro de parse, continua usando a string pura
    }

    _etapas = [
      {
        'title': '🧊 Quebra-gelo / Introdução',
        'content': plan.objective,
        'color': AppColors.azulCeleste,
      },
      {
        'title': '📖 História Bíblica',
        'content': 'Versículo: ${plan.keyVerse}\n\n${plan.storyTopics}',
        'color': AppColors.amareloSol,
      },
      {
        'title': '💡 Aplicação Prática (Quiz)',
        'content': questionsDisplay,
        'color': AppColors.laranjaCriativo,
      },
      {
        'title': '🛠️ Atividade / Dinâmica',
        'content': plan.dynamicActivity,
        'color': AppColors.roxoAcolhedor,
      },
      {
        'title': '🙏 Oração Final',
        'content': plan.prayer,
        'color': AppColors.verdePasto,
      },
    ];
  }

  void _buildEtapasFallback() {
    _etapas = [
      {
        'title': 'Nenhuma aula salva',
        'icon': Icons.warning_rounded,
        'content': 'Você ainda não gerou nenhuma aula com a IA. Volte à tela inicial e crie uma!',
        'color': AppColors.alerta,
      }
    ];
  }

  Future<void> _enviarWhatsApp() async {
    if (_currentPlan == null) return;
    
    final text = '''
*Resumo da Salinha de Hoje!* 🌟

*Tema:* ${_currentPlan!.title}
*Versículo:* ${_currentPlan!.keyVerse}
*Para conversar em família:* O que aprendemos sobre a história hoje?
*Oração:* ${_currentPlan!.prayer}

Boa semana a todas as famílias! 🙏
''';
    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    try {
      await launchUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
        );
      }
    }
  }

  void _showPDFOptionsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Escolha a Atividade', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildPDFOptionCard(ctx, '🎨 Desenho para Colorir', 'Versículo vazado e ilustração', 0),
              _buildPDFOptionCard(ctx, '🧩 Labirinto Bíblico', 'Ajude o personagem a chegar ao fim', 1),
              _buildPDFOptionCard(ctx, '🔍 Jogo dos 7 Erros', 'Encontre as diferenças', 2),
              _buildPDFOptionCard(ctx, '✏️ Caça-Palavras', 'Procure as palavras do tema', 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          )
        ],
      )
    );
  }

  Widget _buildPDFOptionCard(BuildContext ctx, String title, String subtitle, int optionIndex) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: () {
          Navigator.pop(ctx);
          _generateSpecificPDF(optionIndex);
        },
      ),
    );
  }

  Future<void> _generateSpecificPDF(int optionIndex) async {
    final pdf = pw.Document();
    
    final activityNames = [
      'Desenho para Colorir 🎨',
      'Labirinto Bíblico 🧩',
      'Jogo dos 7 Erros 🔍',
      'Caça-Palavras ✏️'
    ];

    final activityName = activityNames[optionIndex];
    final planTitle = _currentPlan?.title ?? "Aula de Hoje";
    final planVerse = _currentPlan?.keyVerse ?? "Seja forte e corajoso! Josué 1:9";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey700, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // CABEÇALHO PEDAGÓGICO DS
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('SALINHA DAS CRIANÇAS 🇨🇭', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                        pw.SizedBox(height: 2),
                        pw.Text('Lição: $planTitle', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                        pw.Text(activityName, style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.blue800, width: 1.5),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Text('Material Didático', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 10),

                // CONTEÚDO PRINCIPAL (EXCLUSIVO DA ATIVIDADE)
                pw.Expanded(
                  child: _buildPDFContent(optionIndex),
                ),
                
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 8),

                // BOX DO VERSÍCULO DO DIA INTEGRADO
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Versículo do Dia 📖', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                      pw.SizedBox(height: 3),
                      pw.Text('"$planVerse"', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey900)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),

                // BLOCO DE IDENTIFICAÇÃO DO ALUNO
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Row(
                        children: [
                          pw.Text('Nome: ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Expanded(
                            child: pw.Container(
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600, width: 1)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Row(
                        children: [
                          pw.Text('Turma: ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Expanded(
                            child: pw.Container(
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600, width: 1)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Row(
                        children: [
                          pw.Text('Data: ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Expanded(
                            child: pw.Container(
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600, width: 1)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      )
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'atividade_salinha.pdf',
    );
  }

  pw.Widget _buildPDFContent(int optionIndex) {
    switch (optionIndex) {
      case 0:
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              'Instrução: Use toda a sua criatividade para colorir e desenhar a história bíblica que aprendemos hoje!',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 12),
            pw.Expanded(
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey500, width: 1, style: pw.BorderStyle.dashed),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                ),
                child: pw.Stack(
                  alignment: pw.Alignment.center,
                  children: [
                    pw.Container(width: 60, height: 180, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 1.5, style: pw.BorderStyle.dashed))),
                    pw.Positioned(top: 45, child: pw.Container(width: 140, height: 50, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 1.5, style: pw.BorderStyle.dashed)))),
                    pw.Container(width: 58, height: 178, color: PdfColors.white),
                    pw.Positioned(top: 46, child: pw.Container(width: 138, height: 48, color: PdfColors.white)),
                  ],
                ),
              ),
            ),
          ],
        );
      case 1:
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              'Instrução: Encontre o caminho correto para levar o personagem ao centro do labirinto!',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 16),
            pw.Expanded(
              child: pw.Center(
                child: pw.SizedBox(
                  width: 320,
                  height: 320,
                  child: pw.Stack(
                    alignment: pw.Alignment.center,
                    children: [
                      pw.Container(width: 320, height: 320, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 3))),
                      pw.Container(width: 270, height: 270, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 3))),
                      pw.Container(width: 220, height: 220, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 3))),
                      pw.Container(width: 170, height: 170, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 3))),
                      pw.Container(width: 120, height: 120, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 3))),
                      pw.Container(width: 70, height: 70, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 3))),
                      
                      pw.Positioned(top: -2, right: 60, child: pw.Container(width: 40, height: 8, color: PdfColors.white)),
                      pw.Positioned(top: 23, left: 80, child: pw.Container(width: 40, height: 8, color: PdfColors.white)),
                      pw.Positioned(bottom: 48, right: 80, child: pw.Container(width: 40, height: 8, color: PdfColors.white)),
                      pw.Positioned(left: 73, top: 120, child: pw.Container(width: 8, height: 40, color: PdfColors.white)),
                      pw.Positioned(top: 98, right: 120, child: pw.Container(width: 40, height: 8, color: PdfColors.white)),
                      pw.Positioned(bottom: 123, left: 120, child: pw.Container(width: 40, height: 8, color: PdfColors.white)),
                      
                      pw.Positioned(top: 10, right: 70, child: pw.Text('🏠 INÍCIO', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Text('CHEGADA 🏁', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      case 2:
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              'Instrução: Compare atentamente as duas figuras abaixo e marque os 7 erros na imagem da direita!',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 16),
            pw.Expanded(
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey700, width: 2),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Stack(
                        children: [
                          pw.Positioned(top: 20, right: 20, child: pw.Container(width: 30, height: 30, decoration: const pw.BoxDecoration(color: PdfColors.grey300, shape: pw.BoxShape.circle))),
                          pw.Positioned(top: 40, left: 30, child: pw.Container(width: 50, height: 18, decoration: const pw.BoxDecoration(color: PdfColors.grey300, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))))),
                          pw.Positioned(bottom: 0, left: 0, right: 0, child: pw.Container(height: 40, color: PdfColors.grey200)),
                          pw.Positioned(bottom: 30, left: 90, child: pw.Container(width: 50, height: 32, decoration: pw.BoxDecoration(color: PdfColors.white, border: pw.Border.all(color: PdfColors.black, width: 1.5), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16))))),
                          pw.Positioned(bottom: 40, left: 125, child: pw.Container(width: 24, height: 24, decoration: const pw.BoxDecoration(color: PdfColors.black, shape: pw.BoxShape.circle))),
                          pw.Positioned(bottom: 40, right: 30, child: pw.Container(width: 12, height: 50, color: PdfColors.black)),
                          pw.Positioned(bottom: 75, right: 20, child: pw.Container(width: 40, height: 40, decoration: const pw.BoxDecoration(color: PdfColors.grey400, shape: pw.BoxShape.circle))),
                          pw.Positioned(top: 70, right: 90, child: pw.Text('v', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
                          pw.Positioned(bottom: 8, left: 25, child: pw.Container(width: 8, height: 24, color: PdfColors.black)),
                          pw.Positioned(bottom: 30, left: 20, child: pw.Container(width: 16, height: 16, decoration: const pw.BoxDecoration(color: PdfColors.grey400, shape: pw.BoxShape.circle))),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey700, width: 2),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Stack(
                        children: [
                          pw.Positioned(top: 40, left: 30, child: pw.Container(width: 50, height: 18, decoration: const pw.BoxDecoration(color: PdfColors.grey300, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))))),
                          pw.Positioned(top: 30, left: 100, child: pw.Container(width: 30, height: 12, decoration: const pw.BoxDecoration(color: PdfColors.grey300, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))))),
                          pw.Positioned(bottom: 0, left: 0, right: 0, child: pw.Container(height: 40, color: PdfColors.grey200)),
                          pw.Positioned(bottom: 30, left: 90, child: pw.Container(width: 50, height: 32, decoration: pw.BoxDecoration(color: PdfColors.white, border: pw.Border.all(color: PdfColors.black, width: 1.5), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16))))),
                          pw.Positioned(bottom: 40, left: 135, child: pw.Container(width: 24, height: 24, decoration: const pw.BoxDecoration(color: PdfColors.black, shape: pw.BoxShape.circle))),
                          pw.Positioned(bottom: 40, right: 30, child: pw.Container(width: 12, height: 50, color: PdfColors.black)),
                          pw.Positioned(bottom: 75, right: 10, child: pw.Container(width: 40, height: 40, decoration: const pw.BoxDecoration(color: PdfColors.grey400, shape: pw.BoxShape.circle))),
                          pw.Positioned(bottom: 8, left: 25, child: pw.Container(width: 8, height: 24, color: PdfColors.black)),
                          pw.Positioned(bottom: 12, right: 90, child: pw.Container(width: 24, height: 8, color: PdfColors.grey500)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 3:
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              'Instrução: Procure e circule as palavras da lista dentro da grade de letras!',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 14),
            pw.Expanded(
              child: pw.Center(
                child: pw.Container(
                  width: 280,
                  height: 280,
                  child: pw.GridView(
                    crossAxisCount: 10,
                    childAspectRatio: 1,
                    children: List.generate(100, (index) {
                      final letras = 'DEUSAMORPAZFEESPERANCAJESUSCRISTOBIBLIA';
                      final char = letras[index % letras.length];
                      return pw.Container(
                        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5)),
                        child: pw.Center(child: pw.Text(char, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
                      );
                    }),
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Palavras para encontrar: 🔍', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.SizedBox(height: 4),
                  pw.Text('DEUS  •  AMOR  •  PAZ  •  FE  •  JESUS  •  BIBLIA', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                ],
              ),
            ),
          ],
        );
      default:
        return pw.SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Modo Ministrar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ) : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.alerta),
            tooltip: 'Gerar PDF',
            onPressed: _showPDFOptionsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.verdePasto),
            tooltip: 'Enviar Resumo',
            onPressed: _enviarWhatsApp,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Column(
            children: [
              if (_etapas.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Etapa ${_expandedIndex + 1} de ${_etapas.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13),
                          ),
                          Text(
                            _etapas[_expandedIndex]['title'].toString().split(' ').sublist(1).join(' '),
                            style: TextStyle(fontWeight: FontWeight.bold, color: _etapas[_expandedIndex]['color'], fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_expandedIndex + 1) / _etapas.length,
                          backgroundColor: Colors.grey[100],
                          valueColor: AlwaysStoppedAnimation<Color>(_etapas[_expandedIndex]['color'].withOpacity(0.8)),
                          minHeight: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: _etapas.length,
                  itemBuilder: (context, index) {
                    final etapa = _etapas[index];
                    final isActive = index == _expandedIndex;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Card(
                        key: _getCardKey(index),
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isActive ? etapa['color'].withOpacity(0.3) : Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: ExpansionTile(
                          backgroundColor: Colors.transparent,
                          collapsedBackgroundColor: Colors.transparent,
                          controller: _getController(index),
                          initiallyExpanded: index == _expandedIndex,
                          iconColor: etapa['color'],
                          collapsedIconColor: etapa['color'],
                          title: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: etapa['color'],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  etapa['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onExpansionChanged: (expanded) {
                            if (expanded) {
                              for (int i = 0; i < _etapas.length; i++) {
                                if (i != index) {
                                  _getController(i).collapse();
                                }
                              }
                              setState(() {
                                _expandedIndex = index;
                              });
                              Future.delayed(const Duration(milliseconds: 250), () {
                                final context = _getCardKey(index).currentContext;
                                if (context != null) {
                                  Scrollable.ensureVisible(
                                    context,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                    alignment: 0.05,
                                  );
                                }
                              });
                            }
                          },
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildEtapaContent(index, etapa, _currentPlan),
                                  if (index < _etapas.length - 1) ...[
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _navigateToStep(index + 1),
                                        icon: const Icon(Icons.arrow_forward, size: 16),
                                        label: const Text('Próxima Etapa'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: etapa['color'],
                                          foregroundColor: Colors.white,
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildEtapaContent(int index, Map<String, dynamic> etapa, LessonPlan? plan) {
    if (plan == null) {
      return Text(
        etapa['content'],
        style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
        textAlign: TextAlign.left,
      );
    }
    
    switch (index) {
      case 0: // Quebra-gelo / Introdução
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              etapa['content'],
              style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChamadaScreen()));
                },
                icon: const Icon(Icons.how_to_reg_rounded, size: 16),
                label: const Text('Fazer Chamada da Turma'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulCeleste,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        );
      case 1: // História Bíblica
        return _buildStoryTopicsContent(plan.storyTopics, plan.keyVerse);
      case 2: // Quiz
        if (_quizQuestions.isEmpty) {
          return Text(
            etapa['content'],
            style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
            textAlign: TextAlign.left,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.help_center_rounded, size: 16, color: AppColors.laranjaCriativo),
                SizedBox(width: 6),
                Text('Perguntas do Quiz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
              ],
            ),
            const SizedBox(height: 12),
            ..._quizQuestions.map((q) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ${q['question']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                      const SizedBox(height: 8),
                      _AnswerToggleWidget(answer: q['answer'].toString(), color: etapa['color']),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      case 3: // Atividade / Dinâmica
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDynamicActivityContent(plan.dynamicActivity, etapa['color']),
            const SizedBox(height: 16),
            _buildCollaborativeGroupsWidget(),
          ],
        );
      case 4: // Oração e Encerramento
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              plan.prayer.isNotEmpty ? plan.prayer : etapa['content'],
              style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            const Text(
              'Próximos Passos:',
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => GamesMenuScreen(linkedLessonTitle: plan.title)));
              },
              icon: const Icon(Icons.palette_rounded, size: 18),
              label: const Text('🎨 Atividades e Desenhos de Apoio'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DsColors.primaryBlue,
                side: const BorderSide(color: DsColors.primaryBlue, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<bool>(
              future: _isCompletedToday(),
              builder: (context, snapshot) {
                final isCompleted = snapshot.data ?? false;
                return ElevatedButton.icon(
                  onPressed: () => _finishLessonAndShowReport(),
                  icon: Icon(isCompleted ? Icons.bar_chart_rounded : Icons.flag_rounded, size: 18),
                  label: Text(isCompleted ? '📊 Ver Relatório da Aula' : '🏁 Finalizar Ministração'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdePasto,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                );
              },
            ),
          ],
        );
      default:
        return Text(
          etapa['content'],
          style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
          textAlign: TextAlign.left,
        );
    }
  }

  Widget _buildStoryTopicsContent(String text, String keyVerse) {
    final lines = text.split('\n');
    final children = <Widget>[];

    children.add(Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bookmark_outline_rounded, size: 16, color: Colors.black54),
              SizedBox(width: 6),
              Text('Versículo do Dia', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            keyVerse,
            style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.black87, height: 1.5),
          ),
        ],
      ),
    ));

    List<String> objectiveLines = [];
    List<String> storytellingLines = [];
    List<String> tipLines = [];
    List<String> genericLines = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.toLowerCase().contains('objetivo') || trimmed.toLowerCase().startsWith('alvo')) {
        objectiveLines.add(trimmed);
      } else if (trimmed.toLowerCase().contains('como contar') || trimmed.toLowerCase().startsWith('roteiro') || trimmed.startsWith('•') || trimmed.startsWith('-')) {
        storytellingLines.add(trimmed);
      } else if (trimmed.toLowerCase().contains('dica') || trimmed.toLowerCase().contains('aplicação')) {
        tipLines.add(trimmed);
      } else {
        genericLines.add(trimmed);
      }
    }

    if (objectiveLines.isNotEmpty || genericLines.isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(Divider(height: 1, color: Colors.grey[200]));
      children.add(const SizedBox(height: 12));
      children.add(const Row(
        children: [
          Icon(Icons.track_changes_rounded, size: 16, color: Colors.black54),
          SizedBox(width: 6),
          Text('🎯 Objetivo / Introdução', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
        ],
      ));
      children.add(const SizedBox(height: 6));
      for (final line in [...objectiveLines, ...genericLines]) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(line, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)),
        ));
      }
    }

    if (storytellingLines.isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(Divider(height: 1, color: Colors.grey[200]));
      children.add(const SizedBox(height: 12));
      children.add(const Row(
        children: [
          Icon(Icons.theater_comedy_rounded, size: 16, color: Colors.black54),
          SizedBox(width: 6),
          Text('🎭 Como contar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
        ],
      ));
      children.add(const SizedBox(height: 6));
      for (final line in storytellingLines) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(line, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)),
        ));
      }
    }

    if (tipLines.isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(Divider(height: 1, color: Colors.grey[200]));
      children.add(const SizedBox(height: 12));
      children.add(const Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 16, color: Colors.black54),
          SizedBox(width: 6),
          Text('💡 Dica para o professor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
        ],
      ));
      children.add(const SizedBox(height: 6));
      for (final line in tipLines) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(line, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildDynamicActivityContent(String text, Color color) {
    final lines = text.split('\n');
    final children = <Widget>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      
      if (trimmed.toLowerCase().startsWith('materiais') || trimmed.toLowerCase().startsWith('material')) {
        children.add(const SizedBox(height: 12));
        children.add(const Row(
          children: [
            Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.roxoAcolhedor),
            SizedBox(width: 6),
            Text('📦 Materiais', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.roxoAcolhedor)),
          ],
        ));
        children.add(const SizedBox(height: 4));
        children.add(Text(trimmed.split(':').sublist(1).join(':').trim(), style: const TextStyle(fontSize: 15)));
      } else if (trimmed.toLowerCase().startsWith('objetivo')) {
        children.add(const SizedBox(height: 12));
        children.add(const Row(
          children: [
            Icon(Icons.track_changes_rounded, size: 16, color: AppColors.roxoAcolhedor),
            SizedBox(width: 6),
            Text('🎯 Objetivo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.roxoAcolhedor)),
          ],
        ));
        children.add(const SizedBox(height: 4));
        children.add(Text(trimmed.split(':').sublist(1).join(':').trim(), style: const TextStyle(fontSize: 15)));
      } else if (trimmed.toLowerCase().startsWith('passo') || trimmed.toLowerCase().startsWith('como fazer')) {
        children.add(const SizedBox(height: 12));
        children.add(const Row(
          children: [
            Icon(Icons.directions_run_rounded, size: 16, color: AppColors.roxoAcolhedor),
            SizedBox(width: 6),
            Text('👣 Passo a passo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.roxoAcolhedor)),
          ],
        ));
        children.add(const SizedBox(height: 4));
        children.add(Text(trimmed.split(':').sublist(1).join(':').trim(), style: const TextStyle(fontSize: 15)));
      } else if (trimmed.toLowerCase().startsWith('tempo') || trimmed.toLowerCase().startsWith('duração')) {
        children.add(const SizedBox(height: 12));
        children.add(const Row(
          children: [
            Icon(Icons.access_time_rounded, size: 16, color: AppColors.roxoAcolhedor),
            SizedBox(width: 6),
            Text('⏱ Tempo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.roxoAcolhedor)),
          ],
        ));
        children.add(const SizedBox(height: 4));
        children.add(Text(trimmed.split(':').sublist(1).join(':').trim(), style: const TextStyle(fontSize: 15)));
      } else {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(trimmed, style: const TextStyle(fontSize: 15)),
        ));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _AnswerToggleWidget extends StatefulWidget {
  final String answer;
  final Color color;
  const _AnswerToggleWidget({required this.answer, required this.color});

  @override
  State<_AnswerToggleWidget> createState() => _AnswerToggleWidgetState();
}

class _AnswerToggleWidgetState extends State<_AnswerToggleWidget> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _show = !_show),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_show ? Icons.visibility_off : Icons.visibility, size: 15, color: widget.color),
                const SizedBox(width: 6),
                Text(
                  _show ? 'Esconder resposta' : '👁️ Mostrar resposta',
                  style: TextStyle(color: widget.color, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade100, width: 0.5),
              ),
              child: Text(
                'Resposta: ${widget.answer}',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 14),
              ),
            ),
          ),
          crossFadeState: _show ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
