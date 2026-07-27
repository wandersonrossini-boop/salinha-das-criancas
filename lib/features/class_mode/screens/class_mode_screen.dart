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
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 4),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('SALINHA DAS CRIANCAS', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Tema: ${_currentPlan?.title ?? "Aula do Dia"}', style: pw.TextStyle(fontSize: 18)),
                pw.SizedBox(height: 20),
                
                // Conteúdo Dinâmico
                pw.Expanded(
                  child: pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 2, style: pw.BorderStyle.dashed),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(15)),
                    ),
                    child: _buildPDFContent(optionIndex),
                  ),
                ),
                
                pw.SizedBox(height: 20),
                pw.Row(
                  children: [
                    pw.Text('Nome do Aluno: ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                        ),
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
      case 0: // Desenho para colorir
        return pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text('Desenhe aqui a historia de hoje!', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 40),
            pw.Container(
              height: 350,
              width: 450,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 2, style: pw.BorderStyle.dashed),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
              ),
              child: pw.Stack(
                alignment: pw.Alignment.center,
                children: [
                  // Uma cruz vazada bem suave no fundo para colorir
                  pw.Container(width: 80, height: 250, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 2))),
                  pw.Positioned(top: 70, child: pw.Container(width: 180, height: 60, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 2)))),
                  pw.Container(width: 76, height: 246, color: PdfColors.white),
                  pw.Positioned(top: 72, child: pw.Container(width: 176, height: 56, color: PdfColors.white)),
                ]
              )
            ),
            pw.SizedBox(height: 40),
            pw.Text('"${_currentPlan?.keyVerse ?? "Deus e amor."}"', style: pw.TextStyle(fontSize: 20, fontStyle: pw.FontStyle.italic)),
          ]
        );
      case 1: // Labirinto
        return pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text('Labirinto Biblico', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('Ajude a chegar ao centro!', style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 20),
            pw.Text('ENTRADA', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Container(
              height: 350,
              width: 350,
              child: pw.Stack(
                alignment: pw.Alignment.center,
                children: [
                  pw.Container(width: 350, height: 350, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 3))),
                  pw.Container(width: 300, height: 300, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 3))),
                  pw.Container(width: 250, height: 250, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 3))),
                  pw.Container(width: 200, height: 200, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 3))),
                  pw.Container(width: 150, height: 150, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 3))),
                  pw.Container(width: 100, height: 100, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 3))),
                  
                  // Aberturas brancas (quebram as paredes)
                  pw.Positioned(top: -2, right: 80, child: pw.Container(width: 40, height: 8, color: PdfColors.white)), // Quebra 350
                  pw.Positioned(top: 23, left: 100, child: pw.Container(width: 40, height: 8, color: PdfColors.white)), // Quebra 300
                  pw.Positioned(bottom: 48, right: 100, child: pw.Container(width: 40, height: 8, color: PdfColors.white)), // Quebra 250
                  pw.Positioned(left: 73, top: 150, child: pw.Container(width: 8, height: 40, color: PdfColors.white)), // Quebra 200
                  pw.Positioned(top: 98, right: 150, child: pw.Container(width: 40, height: 8, color: PdfColors.white)), // Quebra 150
                  pw.Positioned(bottom: 123, left: 150, child: pw.Container(width: 40, height: 8, color: PdfColors.white)), // Quebra 100
                  
                  pw.Text('CHEGADA', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ]
              )
            )
          ]
        );
      case 2: // 7 Erros
        pw.Widget buildScene({required bool isDiff}) {
          return pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 2)),
            child: pw.Stack(
              children: [
                // 1. Sol (Falta na imagem 2)
                if (!isDiff) pw.Positioned(top: 20, right: 20, child: pw.Container(width: 40, height: 40, decoration: const pw.BoxDecoration(color: PdfColors.grey300, shape: pw.BoxShape.circle))),
                
                // 2. Nuvem 1 e 2 (Imagem 2 tem uma nuvem a mais)
                pw.Positioned(top: 40, left: 30, child: pw.Container(width: 60, height: 20, decoration: const pw.BoxDecoration(color: PdfColors.grey300, borderRadius: pw.BorderRadius.all(pw.Radius.circular(10))))),
                if (isDiff) pw.Positioned(top: 30, left: 100, child: pw.Container(width: 40, height: 15, decoration: const pw.BoxDecoration(color: PdfColors.grey300, borderRadius: pw.BorderRadius.all(pw.Radius.circular(10))))),
                
                // Chão
                pw.Positioned(bottom: 0, left: 0, right: 0, child: pw.Container(height: 50, color: PdfColors.grey200)),
                
                // Ovelha corpo
                pw.Positioned(bottom: 40, left: 100, child: pw.Container(width: 60, height: 40, decoration: pw.BoxDecoration(color: PdfColors.white, border: pw.Border.all(color: PdfColors.black, width: 2), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20))))),
                
                // 3. Ovelha cabeca (Deslocada na imagem 2)
                pw.Positioned(bottom: 50, left: isDiff ? 150 : 140, child: pw.Container(width: 30, height: 30, decoration: const pw.BoxDecoration(color: PdfColors.black, shape: pw.BoxShape.circle))),
                
                // Arvore tronco
                pw.Positioned(bottom: 50, right: 40, child: pw.Container(width: 15, height: 60, color: PdfColors.black)),
                
                // 4. Arvore folhas (Deslocada na imagem 2)
                pw.Positioned(bottom: 90, right: isDiff ? 15 : 25, child: pw.Container(width: 50, height: 50, decoration: const pw.BoxDecoration(color: PdfColors.grey400, shape: pw.BoxShape.circle))),
                
                // 5. Pássaro 1 (Falta na imagem 2)
                if (!isDiff) pw.Positioned(top: 80, right: 100, child: pw.Text('v', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
                
                // Flor tronco
                pw.Positioned(bottom: 10, left: 30, child: pw.Container(width: 10, height: 30, color: PdfColors.black)),
                // 6. Flor cabeca (Falta na imagem 2)
                if (!isDiff) pw.Positioned(bottom: 40, left: 25, child: pw.Container(width: 20, height: 20, decoration: const pw.BoxDecoration(color: PdfColors.grey400, shape: pw.BoxShape.circle))),
                
                // 7. Grama extra (Aparece apenas na imagem 2)
                if (isDiff) pw.Positioned(bottom: 15, right: 100, child: pw.Container(width: 30, height: 10, color: PdfColors.grey500)),
              ],
            ),
          );
        }

        return pw.Column(
          children: [
            pw.Text('Jogo dos 7 Erros', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Expanded(
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  pw.Expanded(child: buildScene(isDiff: false)),
                  pw.SizedBox(width: 20),
                  pw.Expanded(child: buildScene(isDiff: true)),
                ]
              )
            )
          ]
        );
      case 3: // Caca Palavras
        return pw.Column(
          children: [
            pw.Text('Caca-Palavras', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Expanded(
              child: pw.GridView(
                crossAxisCount: 10,
                childAspectRatio: 1,
                children: List.generate(100, (index) {
                  // Grid aleatório fictício
                  final letras = 'DEUSAMORPAZFEESPERANCAJESUSCRISTOBIBLIA';
                  final char = letras[index % letras.length];
                  return pw.Container(
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 1)),
                    child: pw.Center(child: pw.Text(char, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
                  );
                })
              )
            ),
            pw.SizedBox(height: 20),
            pw.Text('Procure: DEUS - AMOR - PAZ - FE - JESUS - BIBLIA', style: pw.TextStyle(fontSize: 14)),
          ]
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
                  initiallyExpanded: index == 0,
                  iconColor: etapa['color'],
                  collapsedIconColor: etapa['color'],
                  title: Text(
                    etapa['title'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: etapa['color']), // Reduzido de 26
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0), // Reduzido de 24
                      child: Text(
                        etapa['content'],
                        style: const TextStyle(fontSize: 15, height: 1.4, color: AppColors.textPrimary), // Reduzido de 24 / 1.6
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      bottomNavigationBar: _isLoading ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChamadaScreen()));
                  },
                  icon: const Icon(Icons.how_to_reg_rounded, size: 20),
                  label: const Text('Fazer Chamada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amareloSol,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamsScreen()));
                  },
                  icon: const Icon(Icons.group_add_rounded, size: 20),
                  label: const Text('Criar Equipes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azulCeleste,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
