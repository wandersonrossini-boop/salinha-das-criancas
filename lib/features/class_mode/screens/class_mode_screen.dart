import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/db/database_helper.dart';
import '../../ai_planner/models/lesson_plan.dart';
import '../../games/screens/quiz_screen.dart';
import '../../students/screens/chamada_screen.dart';
import '../../teacher_preparation/screens/teacher_preparation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClassModeScreen extends StatefulWidget {
  final LessonPlan? initialPlan;
  
  const ClassModeScreen({super.key, this.initialPlan});

  @override
  State<ClassModeScreen> createState() => _ClassModeScreenState();
}

class _ClassModeScreenState extends State<ClassModeScreen> {
  bool _isLoading = true;
  LessonPlan? _currentPlan;
  List<LessonPlan> _allPlans = [];
  List<Map<String, dynamic>> _quizQuestions = [];

  List<Map<String, dynamic>> _etapas = [];
  String _selectedAgeBand = '4-7';
  int _currentStepIndex = 0;

  int _presentCount = 0;
  bool _isChamadaPendente = true;
  bool _chamadaReminderDismissed = false;

  bool _isCoordinator = false;
  String _currentTeacherId = '';
  String _currentTeacherName = 'Professor(a)';
  String? _selectedTeacherFilter; // null = Todos (apenas para coordenador)
  List<Map<String, String>> _availableTeachers = [];

  String _planStorageKey(LessonPlan plan) {
    if (plan.id != null) return 'id_${plan.id}';
    return ' custom_${plan.seriesId}_${plan.lessonNumber}_${plan.title.hashCode}';
  }

  MixedAgeStation? findStationByAgeBand(List<MixedAgeStation> stations, String ageBand) {
    final normalizedTarget = MixedAgeStation.normalizeAgeBand(ageBand);
    try {
      return stations.firstWhere(
        (s) => MixedAgeStation.normalizeAgeBand(s.ageBand) == normalizedTarget,
      );
    } catch (_) {
      return stations.isNotEmpty ? stations.first : null;
    }
  }

  Future<void> _saveLessonProgress(
    LessonPlan plan, {
    required int stepIndex,
    bool? isCompleted,
  }) async {
    final clampedStep = stepIndex.clamp(0, 4);
    final updatedPlan = plan.copyWith(
      lastStepIndex: clampedStep,
      isCompleted: isCompleted ?? plan.isCompleted,
    );

    setState(() {
      _currentPlan = updatedPlan;
      final idx = _allPlans.indexWhere(
        (p) => (p.id != null && p.id == plan.id) || (p.title == plan.title && p.lessonNumber == plan.lessonNumber),
      );
      if (idx != -1) {
        _allPlans[idx] = updatedPlan;
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _planStorageKey(updatedPlan);
      await prefs.setString('active_plan_key_$_currentTeacherId', key);
      await prefs.setInt('lesson_step_$key', clampedStep);
      if (isCompleted != null) {
        await prefs.setBool('lesson_completed_$key', isCompleted);
      }
    } catch (e) {
      debugPrint('Erro ao salvar progresso local da aula: $e');
    }

    if (updatedPlan.id != null) {
      try {
        await DatabaseHelper.instance.updateLessonPlan(updatedPlan);
      } catch (e) {
        debugPrint('Erro ao sincronizar progresso da aula no banco: $e');
      }
    }
  }

  Future<void> _selectPlan(LessonPlan plan, {int? overrideStep}) async {
    final step = (overrideStep ?? plan.lastStepIndex).clamp(0, 4);
    setState(() {
      _currentPlan = plan;
      _buildEtapas(plan, initialStep: step);
    });
    await _saveLessonProgress(plan, stepIndex: step);
  }

  List<LessonPlan> get _currentSeriesPlans {
    final plan = _currentPlan;
    if (plan == null) return [];
    if (plan.seriesId.isEmpty && plan.totalLessonsInSeries <= 1) {
      return [plan];
    }
    final series = _allPlans
        .where((p) =>
            p.seriesId.isNotEmpty && p.seriesId == plan.seriesId)
        .toList();
    if (series.isEmpty) return [plan];
    series.sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
    return series;
  }

  LessonPlan? get _nextLessonInSeries {
    final series = _currentSeriesPlans;
    if (series.length <= 1 || _currentPlan == null) return null;
    final currentIdx = series.indexWhere(
      (p) =>
          (p.id != null && p.id == _currentPlan!.id) ||
          (p.lessonNumber == _currentPlan!.lessonNumber && p.title == _currentPlan!.title),
    );
    if (currentIdx >= 0 && currentIdx + 1 < series.length) {
      return series[currentIdx + 1];
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _initTeacherAndLoadPlans();
  }

  Future<void> _initTeacherAndLoadPlans() async {
    try {
      final ctx = await DatabaseHelper.instance.getCurrentTeacherContext();
      _isCoordinator = ctx['isCoordinator'] == true;
      _currentTeacherId = (ctx['id'] ?? '').toString();
      _currentTeacherName = (ctx['name'] ?? 'Professor(a)').toString();

      if (_isCoordinator) {
        final active = await DatabaseHelper.instance.fetchActiveTeachers();
        _availableTeachers = [
          {'id': _currentTeacherId, 'name': '$_currentTeacherName (Coord.)'},
          ...active.where((t) => t['id'] != _currentTeacherId),
        ];
        if (widget.initialPlan != null &&
            widget.initialPlan!.teacherId.isNotEmpty) {
          _selectedTeacherFilter = widget.initialPlan!.teacherId;
        }
      }
    } catch (e) {
      debugPrint("Erro ao inicializar contexto do professor: $e");
    }
    await _loadLatestPlan();
  }

  Future<void> _loadLatestPlan() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint("Erro ao obter SharedPreferences: $e");
    }

    try {
      debugPrint("ClassModeScreen: carregando planos salvos...");
      final fetchedPlans = await DatabaseHelper.instance
          .fetchAllLessonPlans(filterTeacherId: _selectedTeacherFilter)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => <LessonPlan>[],
          );

      // Mescla progresso salvo localmente (SharedPreferences) com os planos carregados
      _allPlans = fetchedPlans.map((plan) {
        if (prefs == null) return plan;
        final key = _planStorageKey(plan);
        final savedStep = prefs.getInt('lesson_step_$key');
        final savedCompleted = prefs.getBool('lesson_completed_$key');
        return plan.copyWith(
          lastStepIndex: savedStep ?? plan.lastStepIndex,
          isCompleted: (savedCompleted ?? false) || plan.isCompleted,
        );
      }).toList();

      if (widget.initialPlan != null &&
          (_selectedTeacherFilter == null ||
              widget.initialPlan!.teacherId == _selectedTeacherFilter)) {
        final key = _planStorageKey(widget.initialPlan!);
        final savedStep = prefs?.getInt('lesson_step_$key');
        final savedCompleted = prefs?.getBool('lesson_completed_$key');
        _currentPlan = widget.initialPlan!.copyWith(
          lastStepIndex: savedStep ?? widget.initialPlan!.lastStepIndex,
          isCompleted: (savedCompleted ?? false) || widget.initialPlan!.isCompleted,
        );
        _allPlans.removeWhere((p) => p == _currentPlan);
        _allPlans.insert(0, _currentPlan!);
        _buildEtapas(_currentPlan!, initialStep: _currentPlan!.lastStepIndex);
      } else if (_allPlans.isNotEmpty) {
        LessonPlan? restoredPlan;
        final activeKey = prefs?.getString('active_plan_key_$_currentTeacherId');
        if (activeKey != null && activeKey.isNotEmpty) {
          for (final p in _allPlans) {
            if (_planStorageKey(p) == activeKey) {
              restoredPlan = p;
              break;
            }
          }
        }

        if (restoredPlan != null) {
          _currentPlan = restoredPlan;
        } else {
          final firstPlan = _allPlans.first;
          if (firstPlan.seriesId.isNotEmpty) {
            final sameSeries = _allPlans
                .where((p) => p.seriesId == firstPlan.seriesId)
                .toList()
              ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
            // Seleciona a primeira aula ainda não concluída da série (ou a primeira se todas concluídas)
            _currentPlan = sameSeries.firstWhere(
              (p) => !p.isCompleted,
              orElse: () => sameSeries.first,
            );
          } else {
            _currentPlan = firstPlan;
          }
        }
        _buildEtapas(_currentPlan!, initialStep: _currentPlan!.lastStepIndex);
      } else {
        _currentPlan = null;
        _buildEtapasFallback();
      }
    } catch (e, stack) {
      debugPrint("Erro em _loadLatestPlan: $e\n$stack");
      _buildEtapasFallback();
    }

    try {
      if (prefs != null) {
        final todayStr = DateTime.now().toIso8601String().split('T').first;
        final savedDate = prefs.getString('attendance_date') ?? '';
        final presentIds = prefs.getStringList('present_student_ids') ?? [];
        final isTodayAttendance = savedDate == todayStr && presentIds.isNotEmpty;
        _presentCount = isTodayAttendance ? presentIds.length : presentIds.length;
        _isChamadaPendente = presentIds.isEmpty || (savedDate.isNotEmpty && savedDate != todayStr);
        if (_isChamadaPendente) {
          _presentCount = 0;
        }
        _chamadaReminderDismissed =
            prefs.getBool('chamada_dismissed_$todayStr') ?? false;
      }
    } catch (e) {
      debugPrint("Erro ao carregar lista de presença: $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _buildEtapas(LessonPlan plan, {int? initialStep}) {
    try {
      if (plan.stations.isNotEmpty) {
        final availableBands = plan.stations
            .map((s) => MixedAgeStation.normalizeAgeBand(s.ageBand))
            .toSet();
        if (!availableBands.contains(_selectedAgeBand) && availableBands.isNotEmpty) {
          _selectedAgeBand = availableBands.first;
        }
      }
      
      String questionsDisplay = plan.questions;
      _quizQuestions = [];

      try {
        final decoded = jsonDecode(plan.questions);
        if (decoded is List) {
          _quizQuestions = [];
          for (final x in decoded) {
            if (x is Map) {
              _quizQuestions.add(Map<String, dynamic>.from(x));
            }
          }
          if (_quizQuestions.isNotEmpty) {
            questionsDisplay = _quizQuestions.map((q) => '${q['question'] ?? ''}\nResposta: ${q['answer'] ?? ''}').join('\n\n');
          }
        }
      } catch (e) {
        debugPrint("Aviso: erro ao decodificar questions do plano: $e");
      }

      _etapas = [
        {
          'title': 'Quebra-gelo / Introdução',
          'content': plan.objective,
          'color': AppColors.azulCeleste,
        },
        {
          'title': 'História Bíblica',
          'content': 'Versículo: ${plan.keyVerse}\n\n${plan.storyTopics}',
          'color': AppColors.amareloSol,
        },
        {
          'title': 'Aplicação Prática (Quiz)',
          'content': questionsDisplay,
          'color': AppColors.laranjaCriativo,
        },
        {
          'title': 'Atividade / Dinâmica',
          'content': plan.stations.isNotEmpty ? '' : plan.dynamicActivity,
          'isDynamic': plan.stations.isNotEmpty,
          'color': AppColors.roxoAcolhedor,
        },
        {
          'title': 'Oração Final',
          'content': plan.prayer,
          'color': AppColors.verdePasto,
        },
      ];
      _currentStepIndex = (initialStep ?? plan.lastStepIndex).clamp(0, _etapas.length - 1);
    } catch (e, stack) {
      debugPrint("Erro ao construir etapas do plano: $e\n$stack");
      _buildEtapasFallback();
    }
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
              _buildPDFOptionCard(ctx, 'Desenho para Colorir', 'Versículo vazado e ilustração', 0),
              _buildPDFOptionCard(ctx, 'Labirinto Bíblico', 'Ajude o personagem a chegar ao fim', 1),
              _buildPDFOptionCard(ctx, 'Jogo dos 7 Erros', 'Encontre as diferenças', 2),
              _buildPDFOptionCard(ctx, 'Caça-Palavras', 'Procure as palavras do tema', 3),
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

  Future<void> _openTeacherStudy([LessonPlan? targetPlan]) async {
    final plan = targetPlan ?? _currentPlan;
    if (plan == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherPreparationScreen(
          plan: plan,
          onStartClass: () {
            if (mounted && targetPlan != null) {
              _selectPlan(targetPlan);
            }
          },
        ),
      ),
    );
    await _loadLatestPlan();
  }

  Future<void> _dismissChamadaReminder() async {
    setState(() {
      _chamadaReminderDismissed = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      await prefs.setBool('chamada_dismissed_$todayStr', true);
    } catch (e) {
      debugPrint('Erro ao dispensar lembrete de chamada: $e');
    }
  }

  Widget _buildOptionalChamadaReminderBanner() {
    if (!_isChamadaPendente || _chamadaReminderDismissed || _currentStepIndex != 0) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.fact_check_outlined, color: Color(0xFFD97706), size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Chamada ainda não registada. Pode fazê-la agora ou mais tarde.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12.5,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: Color(0xFF92400E),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ChamadaScreen()));
              await _loadLatestPlan();
            },
            icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
            label: const Text(
              'Fazer Chamada',
              style: TextStyle(fontFamily: 'Fredoka', fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 34),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 6),
          OutlinedButton(
            onPressed: _dismissChamadaReminder,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF92400E),
              side: const BorderSide(color: Color(0xFFFCD34D)),
              backgroundColor: Colors.white.withOpacity(0.6),
              minimumSize: const Size(0, 34),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Fazer depois',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showSequenceModal() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            // Agrupa planos por série (ou individual)
            final Map<String, List<LessonPlan>> grouped = {};
            for (final p in _allPlans) {
              final key = p.seriesId.isNotEmpty
                  ? p.seriesId
                  : 'single_${p.id ?? p.title}';
              grouped.putIfAbsent(key, () => []).add(p);
            }
            for (final list in grouped.values) {
              list.sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              elevation: 10,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // CABEÇALHO DO MODAL DE SEQUÊNCIA
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                      child: Row(
                        children: [
                          const Icon(Icons.view_list_rounded, color: AppColors.azulCeleste, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sequência de Aulas',
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Professor(a): ${(_currentPlan != null && _currentPlan!.teacherName.isNotEmpty) ? _currentPlan!.teacherName : _currentTeacherName}',
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    if (_isCoordinator && _availableTeachers.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_search_rounded, size: 18, color: AppColors.roxoAcolhedor),
                              const SizedBox(width: 8),
                              const Text(
                                'Filtrar Professor:',
                                style: TextStyle(fontFamily: 'Fredoka', fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String?>(
                                    value: _selectedTeacherFilter,
                                    isDense: true,
                                    isExpanded: true,
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('Todos os Professores', style: TextStyle(fontSize: 12)),
                                      ),
                                      ..._availableTeachers.map((t) {
                                        return DropdownMenuItem<String?>(
                                          value: t['id'],
                                          child: Text(t['name'] ?? 'Professor(a)', style: const TextStyle(fontSize: 12)),
                                        );
                                      }),
                                    ],
                                    onChanged: (val) async {
                                      setState(() {
                                        _selectedTeacherFilter = val;
                                        _isLoading = true;
                                      });
                                      await _loadLatestPlan();
                                      if (ctx.mounted) setModalState(() {});
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),

                    // LISTA EM LARGURA TOTAL DE TODAS AS AULAS DA SEQUÊNCIA
                    Flexible(
                      child: _allPlans.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Center(
                                child: Text(
                                  'Nenhuma aula salva ainda.',
                                  style: TextStyle(fontFamily: 'Nunito', color: Color(0xFF64748B)),
                                ),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.all(16),
                              shrinkWrap: true,
                              children: grouped.entries.map((entry) {
                                final lessons = entry.value;
                                final first = lessons.first;
                                final total = lessons.length;
                                final themeTitle = first.seriesTheme.isNotEmpty
                                    ? first.seriesTheme
                                    : first.title.replaceFirst(RegExp(r'^Aula\s*\d+\s*[-:]\s*', caseSensitive: false), '');

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.azulCeleste,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                          child: Text(
                                            total > 1 ? 'Série de $total Aulas' : 'Aula Individual',
                                            style: const TextStyle(
                                              fontFamily: 'Fredoka',
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Tema: $themeTitle',
                                              style: const TextStyle(
                                                fontFamily: 'Fredoka',
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                          if (first.seriesId.isNotEmpty && total > 1)
                                            IconButton(
                                              tooltip: 'Excluir série inteira',
                                              visualDensity: VisualDensity.compact,
                                              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 20),
                                              onPressed: () async {
                                                await DatabaseHelper.instance.deleteLessonSeries(first.seriesId);
                                                await _loadLatestPlan();
                                                if (ctx.mounted) setModalState(() {});
                                              },
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      ...List.generate(lessons.length, (idx) {
                                        final itemPlan = lessons[idx];
                                        final isSelected = itemPlan.id == _currentPlan?.id && itemPlan.title == _currentPlan?.title;
                                        return Container(
                                          margin: EdgeInsets.only(bottom: idx == lessons.length - 1 ? 0 : 8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: isSelected ? AppColors.azulCeleste : const Color(0xFFE2E8F0),
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(14),
                                            onTap: () {
                                              _selectPlan(itemPlan);
                                              Navigator.pop(dialogContext);
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: itemPlan.isCompleted
                                                              ? AppColors.verdePasto
                                                              : (isSelected ? AppColors.azulCeleste : const Color(0xFFE2E8F0)),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          itemPlan.isCompleted ? '✓ ${idx + 1}/$total' : '${idx + 1}/$total',
                                                          style: TextStyle(
                                                            fontFamily: 'Fredoka',
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                            color: (isSelected || itemPlan.isCompleted) ? Colors.white : const Color(0xFF334155),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    itemPlan.title,
                                                                    style: const TextStyle(
                                                                      fontFamily: 'Fredoka',
                                                                      fontSize: 14,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: Color(0xFF0F172A),
                                                                    ),
                                                                  ),
                                                                ),
                                                                if (itemPlan.isCompleted)
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(0xFFDCFCE7),
                                                                      borderRadius: BorderRadius.circular(6),
                                                                    ),
                                                                    child: const Text(
                                                                      'Concluída',
                                                                      style: TextStyle(
                                                                        fontFamily: 'Fredoka',
                                                                        fontSize: 10,
                                                                        fontWeight: FontWeight.bold,
                                                                        color: Color(0xFF15803D),
                                                                      ),
                                                                    ),
                                                                  )
                                                                else if (itemPlan.lastStepIndex > 0)
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(0xFFDBEAFE),
                                                                      borderRadius: BorderRadius.circular(6),
                                                                    ),
                                                                    child: Text(
                                                                      'Etapa ${itemPlan.lastStepIndex + 1}/5',
                                                                      style: const TextStyle(
                                                                        fontFamily: 'Fredoka',
                                                                        fontSize: 10,
                                                                        fontWeight: FontWeight.bold,
                                                                        color: Color(0xFF1D4ED8),
                                                                      ),
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                            const SizedBox(height: 3),
                                                            Text(
                                                              itemPlan.keyVerse,
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: const TextStyle(
                                                                fontFamily: 'Nunito',
                                                                fontSize: 12,
                                                                color: Color(0xFF64748B),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (itemPlan.id != null)
                                                        IconButton(
                                                          tooltip: 'Excluir esta aula',
                                                          visualDensity: VisualDensity.compact,
                                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                                          onPressed: () async {
                                                            await DatabaseHelper.instance.deleteLessonPlan(itemPlan.id!);
                                                            await _loadLatestPlan();
                                                            if (ctx.mounted) setModalState(() {});
                                                          },
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      OutlinedButton.icon(
                                                        onPressed: () {
                                                          Navigator.pop(dialogContext);
                                                          _openTeacherStudy(itemPlan);
                                                        },
                                                        icon: const Icon(Icons.menu_book_rounded, size: 14),
                                                        label: const Text(
                                                          'Estudar Aula',
                                                          style: TextStyle(fontFamily: 'Fredoka', fontSize: 12, fontWeight: FontWeight.bold),
                                                        ),
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor: const Color(0xFF1E3A8A),
                                                          side: const BorderSide(color: Color(0xFF93C5FD)),
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                          visualDensity: VisualDensity.compact,
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      ElevatedButton.icon(
                                                        onPressed: () {
                                                          _selectPlan(itemPlan);
                                                          Navigator.pop(dialogContext);
                                                        },
                                                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                                                        label: Text(
                                                          isSelected ? 'Aula Atual' : 'Selecionar',
                                                          style: const TextStyle(fontFamily: 'Fredoka', fontSize: 12, fontWeight: FontWeight.bold),
                                                        ),
                                                        style: ElevatedButton.styleFrom(
                                                          minimumSize: Size.zero,
                                                          backgroundColor: AppColors.azulCeleste,
                                                          foregroundColor: Colors.white,
                                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                          visualDensity: VisualDensity.compact,
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                          elevation: 0,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompactTopBar() {
    final plan = _currentPlan;
    if (plan == null) return const SizedBox.shrink();

    final seriesPlans = _currentSeriesPlans;
    final totalCount = seriesPlans.length > plan.totalLessonsInSeries
        ? seriesPlans.length
        : plan.totalLessonsInSeries;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _openTeacherStudy(plan),
              icon: const Icon(Icons.school_rounded, size: 18),
              label: const Text(
                'Estudo do Professor',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showSequenceModal,
              icon: const Icon(Icons.format_list_numbered_rounded, size: 18, color: AppColors.azulCeleste),
              label: Text(
                totalCount > 1
                    ? 'Sequência (${plan.lessonNumber}/$totalCount)'
                    : 'Trocar Aula (${_allPlans.length})',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.azulCeleste, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherStudyAccordionCard() {
    final plan = _currentPlan;
    if (plan == null) return const SizedBox.shrink();
    final core = plan.biblicalCore;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFBFDBFE), width: 1.5),
      ),
      color: const Color(0xFFF8FAFC),
      elevation: 2,
      child: ExpansionTile(
        leading: const Icon(Icons.menu_book_rounded, color: Color(0xFF1E3A8A)),
        iconColor: const Color(0xFF1E3A8A),
        collapsedIconColor: const Color(0xFF1E3A8A),
        title: const Text(
          'Preparo e Estudo do Professor',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        subtitle: Text(
          core != null && core.passage.isNotEmpty
              ? 'Base Bíblica: ${core.passage}'
              : 'Toque para estudar a lição antes de ministrar',
          style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (core != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VERDADE CENTRAL',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          core.centralTruth,
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (core.theologicalCore.isNotEmpty) ...[
                    const Text(
                      'Coração Teológico (Para o Professor):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      core.theologicalCore,
                      style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (core.textSays.isNotEmpty) ...[
                    const Text(
                      'O que o texto bíblico diz:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    ...core.textSays.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $s', style: const TextStyle(fontSize: 13.5, height: 1.35, color: Color(0xFF334155))),
                        )),
                    const SizedBox(height: 10),
                  ],
                  if (core.historicalContext.isNotEmpty) ...[
                    const Text(
                      'Contexto Histórico:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    ...core.historicalContext.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $s', style: const TextStyle(fontSize: 13.5, height: 1.35, color: Color(0xFF475569))),
                        )),
                    const SizedBox(height: 10),
                  ],
                  if (core.textAllowsToConclude.isNotEmpty) ...[
                    const Text(
                      'O que o texto permite concluir:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    ...core.textAllowsToConclude.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $s', style: const TextStyle(fontSize: 13.5, height: 1.35, color: Color(0xFF334155))),
                        )),
                    const SizedBox(height: 10),
                  ],
                  if (core.textDoesNotSay.isNotEmpty) ...[
                    const Text(
                      'Cuidado ao ensinar (O que o texto NÃO diz):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF6D28D9)),
                    ),
                    const SizedBox(height: 4),
                    ...core.textDoesNotSay.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $s', style: const TextStyle(fontSize: 13.5, height: 1.35, color: Color(0xFF6D28D9))),
                        )),
                    const SizedBox(height: 12),
                  ],
                ] else ...[
                  Text(
                    'Objetivo da Lição: ${plan.objective}\n\nVersículo-Chave: ${plan.keyVerse}',
                    style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openTeacherStudy(plan),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text(
                      'Abrir Tela Completa de Estudo e Edição',
                      style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = _currentPlan;
    final prefix = (plan != null && plan.totalLessonsInSeries > 1)
        ? '[${plan.lessonNumber}/${plan.totalLessonsInSeries}] '
        : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _allPlans.isNotEmpty ? _showSequenceModal : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      plan != null ? '$prefix${plan.title}' : 'Modo Ministrar',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                        fontFamily: 'Fredoka',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_allPlans.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.black87),
                  ],
                ],
              ),
              if (!_isLoading && _etapas.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Progresso: Etapa ${_currentStepIndex + 1} de ${_etapas.length}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                    if (plan != null && plan.isCompleted) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '✓ Concluída',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ) : null,
        actions: [
          if (!_isLoading)
            GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const ChamadaScreen()));
                _loadLatestPlan();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: _isChamadaPendente
                      ? AppColors.azulCeleste.withOpacity(0.10)
                      : AppColors.verdePasto.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isChamadaPendente ? AppColors.azulCeleste : AppColors.verdePasto,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isChamadaPendente ? Icons.fact_check_outlined : Icons.check_circle_outline_rounded,
                      size: 14,
                      color: _isChamadaPendente ? AppColors.azulCeleste : AppColors.verdePasto,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isChamadaPendente ? 'Chamada' : '$_presentCount Presentes',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isChamadaPendente ? AppColors.azulCeleste : AppColors.verdePasto,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
        : ListView(
            padding: const EdgeInsets.all(12.0),
            children: [
              _buildCompactTopBar(),
              _buildOptionalChamadaReminderBanner(),
              _buildTeacherStudyAccordionCard(),
              ...List.generate(_etapas.length, (index) {
                final etapa = _etapas[index];
                final nextInSeries = _nextLessonInSeries;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  child: ExpansionTile(
                    key: Key('etapa_${_currentPlan?.id ?? 0}_${index}_${_currentStepIndex == index}'),
                    initiallyExpanded: index == _currentStepIndex,
                    onExpansionChanged: (expanded) {
                      if (expanded && _currentStepIndex != index && _currentPlan != null) {
                        setState(() {
                          _currentStepIndex = index;
                        });
                        _saveLessonProgress(_currentPlan!, stepIndex: index);
                      }
                    },
                    iconColor: etapa['color'],
                    collapsedIconColor: etapa['color'],
                    title: Text(
                      etapa['title'],
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: etapa['color']),
                    ),
                    children: [
                      if (etapa['isDynamic'] == true && _currentPlan != null && _currentPlan!.stations.isNotEmpty)
                        Builder(builder: (context) {
                          final bandsList = _currentPlan!.stations
                              .map((s) => MixedAgeStation.normalizeAgeBand(s.ageBand))
                              .toSet()
                              .toList();
                          final activeValue = bandsList.contains(_selectedAgeBand) 
                              ? _selectedAgeBand 
                              : (bandsList.isNotEmpty ? bandsList.first : null);

                          if (activeValue == null) return const SizedBox();

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: DropdownButton<String>(
                              value: activeValue,
                              isExpanded: true,
                              items: bandsList.map((band) {
                                final formattedBand = band.replaceAll('-', '–');
                                return DropdownMenuItem<String>(
                                  value: band,
                                  child: Text(
                                    'Faixa Etária: $formattedBand anos',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedAgeBand = val);
                              },
                            ),
                          );
                        }),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Builder(builder: (context) {
                          if (etapa['isDynamic'] == true && _currentPlan != null) {
                            final station = findStationByAgeBand(_currentPlan!.stations, _selectedAgeBand);
                            if (station == null) {
                              return const Text('Adaptação ainda não disponível para esta faixa.', style: TextStyle(color: AppColors.textPrimary));
                            }
                            final materialsText = (station.materials as dynamic) is List ? (station.materials as List).join(', ') : '';
                            final stepsText = (station.executionSteps as dynamic) is List ? (station.executionSteps as List).join('\n') : '';
                            return Text(
                              'Duração: ${station.duration}\nMateriais: $materialsText\n\nPreparação:\n${station.preparation}\n\nDescrição:\n${station.description}\n\nPassos:\n$stepsText',
                              style: const TextStyle(fontSize: 15, height: 1.4, color: AppColors.textPrimary),
                            );
                          }
                          if (etapa['title'].contains('Quiz')) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  etapa['content'],
                                  style: const TextStyle(fontSize: 15, height: 1.4, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(plan: _currentPlan)));
                                    },
                                    icon: const Icon(Icons.quiz_rounded),
                                    label: const Text('Jogar Quiz com a Turma', style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.laranjaCriativo,
                                      side: const BorderSide(color: AppColors.laranjaCriativo),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                          return Text(
                            etapa['content'],
                            style: const TextStyle(fontSize: 15, height: 1.4, color: AppColors.textPrimary),
                            textAlign: TextAlign.left,
                          );
                        }),
                      ),
                      if (index == _currentStepIndex)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (index < _etapas.length - 1)
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final nextStep = index + 1;
                                      setState(() {
                                        _currentStepIndex = nextStep;
                                      });
                                      if (_currentPlan != null) {
                                        await _saveLessonProgress(_currentPlan!, stepIndex: nextStep);
                                      }
                                    },
                                    icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                                    label: Text(
                                      'Próxima Etapa (${index + 2}/${_etapas.length})',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: etapa['color'],
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                )
                              else ...[
                                if (_currentPlan != null && _currentPlan!.isCompleted)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF86EFAC)),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.verified_rounded, color: Color(0xFF15803D), size: 18),
                                        SizedBox(width: 6),
                                        Text(
                                          'Esta aula já está registada como concluída!',
                                          style: TextStyle(
                                            fontFamily: 'Fredoka',
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF15803D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      if (_currentPlan != null) {
                                        await _saveLessonProgress(
                                          _currentPlan!,
                                          stepIndex: index,
                                          isCompleted: true,
                                        );
                                      }
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Aula concluída e registada com sucesso! 🎉'),
                                          backgroundColor: AppColors.verdePasto,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                                    label: Text(
                                      (_currentPlan != null && _currentPlan!.isCompleted)
                                          ? 'Aula Concluída ✓'
                                          : 'Concluir e Registar Aula',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.verdePasto,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                if (nextInSeries != null) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 46,
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        if (_currentPlan != null) {
                                          await _saveLessonProgress(
                                            _currentPlan!,
                                            stepIndex: index,
                                            isCompleted: true,
                                          );
                                        }
                                        await _selectPlan(nextInSeries, overrideStep: 0);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Aula concluída! Avançando para Aula ${nextInSeries.lessonNumber} da sequência.'),
                                            backgroundColor: AppColors.azulCeleste,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.skip_next_rounded, color: AppColors.azulCeleste),
                                      label: Text(
                                        'Concluir e Ir para Aula ${nextInSeries.lessonNumber} da Sequência',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.azulCeleste,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: AppColors.azulCeleste, width: 1.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
    );
  }
}
