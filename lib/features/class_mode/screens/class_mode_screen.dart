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
import '../../roulette/screens/roulette_screen.dart';
import '../../students/screens/chamada_screen.dart';
import '../../teams/screens/teams_screen.dart';
import '../../../core/utils/safe_converters.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String _selectedAgeBand = '4-6';
  int _currentStepIndex = 0;

  int _presentCount = 0;
  bool _isChamadaPendente = true;

  MixedAgeStation? findStationByAgeBand(List stations, String ageBand) {
    final matches = stations.where((item) => item.ageBand == ageBand).toList();
    if (matches.length > 1) {
      print('Aviso: Estação duplicada para a faixa $ageBand, utilizando a primeira ocorrência.');
    }
    return matches.firstOrNull;
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
    } else {
      // Fallback
      _buildEtapasFallback();
    }

    final prefs = await SharedPreferences.getInstance();
    final presentIds = prefs.getStringList('present_student_ids') ?? [];
    _presentCount = presentIds.length;
    _isChamadaPendente = presentIds.isEmpty;

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
        'content': plan.stations.isNotEmpty ? '' : plan.dynamicActivity,
        'isDynamic': plan.stations.isNotEmpty,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Modo Ministrar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (!_isLoading && _etapas.isNotEmpty)
              Text(
                'Progresso: Etapa ${_currentStepIndex + 1} de ${_etapas.length}',
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
          ],
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
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: _isChamadaPendente ? AppColors.amareloSol.withOpacity(0.12) : AppColors.verdePasto.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isChamadaPendente ? AppColors.amareloSol : AppColors.verdePasto,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isChamadaPendente ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                      size: 14,
                      color: _isChamadaPendente ? AppColors.amareloSol : AppColors.verdePasto,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isChamadaPendente ? 'Chamada Pendente' : '$_presentCount Presentes',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isChamadaPendente ? AppColors.amareloSol : AppColors.verdePasto,
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
        : ListView.builder(
            padding: const EdgeInsets.all(12.0), // Reduzido de 16
            itemCount: _etapas.length,
            itemBuilder: (context, index) {
              final etapa = _etapas[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12), // Reduzido de 24
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3, // Reduzido de 6
                child: ExpansionTile(
                  key: Key('etapa_${index}_${_currentStepIndex == index}'),
                  initiallyExpanded: index == _currentStepIndex,
                  iconColor: etapa['color'],
                  collapsedIconColor: etapa['color'],
                  title: Text(
                    etapa['title'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: etapa['color']), // Reduzido de 26
                  ),
                  children: [
                    if (etapa['isDynamic'] == true && _currentPlan != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: DropdownButton<String>(
                          value: _selectedAgeBand,
                          isExpanded: true,
                          items: _currentPlan!.stations.map((s) => s.ageBand).toSet().map((band) {
                            return DropdownMenuItem(value: band, child: Text('Faixa Etária: $band'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedAgeBand = val);
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0), // Reduzido de 24
                      child: Builder(builder: (context) {
                        if (etapa['isDynamic'] == true && _currentPlan != null) {
                          final station = findStationByAgeBand(_currentPlan!.stations, _selectedAgeBand);
                          if (station == null) {
                            return const Text('Adaptação ainda não disponível para esta faixa.', style: TextStyle(color: AppColors.textPrimary));
                          }
                          return Text(
                            'Duração: ${station.duration}\nMateriais: ${station.materials.join(', ')}\n\nPreparação:\n${station.preparation}\n\nDescrição:\n${station.description}\n\nPassos:\n${station.executionSteps.join('\n')}',
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
                          style: const TextStyle(fontSize: 15, height: 1.4, color: AppColors.textPrimary), // Reduzido de 24 / 1.6
                          textAlign: TextAlign.left,
                        );
                      }),
                    ),
                    if (index == _currentStepIndex)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (index < _etapas.length - 1) {
                                setState(() {
                                  _currentStepIndex++;
                                });
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            icon: Icon(
                              index < _etapas.length - 1 ? Icons.arrow_forward_rounded : Icons.check_circle_rounded,
                              color: Colors.white,
                            ),
                            label: Text(
                              index < _etapas.length - 1 ? 'Próxima Etapa' : 'Concluir Aula',
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
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
