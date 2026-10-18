import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/db/database_helper.dart';
import '../services/gemini_service.dart';
import '../models/lesson_plan.dart';
import '../../teacher_preparation/screens/teacher_preparation_screen.dart';
import '../../../core/components/mascot/mascot_widget.dart';
import '../../../core/design_system/colors.dart';

class AiPlannerScreen extends StatefulWidget {
  final ValueChanged<LessonPlan>? onPlanGenerated;

  const AiPlannerScreen({super.key, this.onPlanGenerated});

  @override
  State<AiPlannerScreen> createState() => _AiPlannerScreenState();
}

class _AiPlannerScreenState extends State<AiPlannerScreen> {
  final _temaController = TextEditingController();

  String _selectedIdade = '4-7 anos';
  final List<String> _idades = ['4-7 anos', '8-11 anos', 'Turma Mista (4 a 11 anos)'];
  String _selectedAulas = '4';
  final List<String> _aulas = ['1', '2', '3', '4', '5'];
  
  bool _isLoading = false;
  final GeminiService _geminiService = GeminiService();

  bool _isCoordinator = false;
  String _selectedTeacherId = 'admin';
  String _selectedTeacherName = 'Administrador';
  List<Map<String, String>> _availableTeachers = [
    {'id': 'admin', 'name': 'Administrador (Geral)'},
  ];
  List<LessonPlan> _teacherPlans = [];
  bool _loadingPlans = true;

  @override
  void initState() {
    super.initState();
    _initTeacherAndPlans();
  }

  Future<void> _initTeacherAndPlans() async {
    try {
      final ctx = await DatabaseHelper.instance.getCurrentTeacherContext();
      final isCoord = ctx['isCoordinator'] == true;
      final currentId = ctx['id']?.toString() ?? 'admin';
      final currentName = ctx['name']?.toString() ?? 'Professor';

      List<Map<String, String>> teachers = [
        {'id': currentId, 'name': currentName},
      ];
      if (isCoord) {
        teachers = await DatabaseHelper.instance.fetchActiveTeachers();
        if (!teachers.any((t) => t['id'] == currentId)) {
          teachers.insert(0, {'id': currentId, 'name': currentName});
        }
      }

      if (!mounted) return;
      setState(() {
        _isCoordinator = isCoord;
        _availableTeachers = teachers;
        _selectedTeacherId = currentId;
        _selectedTeacherName = teachers
            .firstWhere((t) => t['id'] == currentId, orElse: () => teachers.first)['name']!;
      });

      await _loadTeacherPlans();
    } catch (e) {
      debugPrint('Erro ao inicializar professor no planejador: $e');
      if (mounted) {
        setState(() => _loadingPlans = false);
      }
    }
  }

  Future<void> _loadTeacherPlans() async {
    if (!mounted) return;
    setState(() => _loadingPlans = true);
    try {
      final plans = await DatabaseHelper.instance.fetchAllLessonPlans(
        filterTeacherId: _selectedTeacherId,
      );
      if (!mounted) return;
      setState(() {
        _teacherPlans = plans;
        _loadingPlans = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingPlans = false);
      }
    }
  }

  Future<void> _gerarAula() async {
    if (_isLoading) return;
    if (_temaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o tema principal antes de gerar a sequência de aulas.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final int count = int.tryParse(_selectedAulas) ?? 4;
      debugPrint("Iniciando geração de aula(s): tema='${_temaController.text.trim()}', idade='$_selectedIdade', qtd=$count, prof='$_selectedTeacherName'");
      
      final plans = await _geminiService.generateMonthlySeries(
        _temaController.text.trim(),
        _selectedIdade,
        count,
        isIndividual: count == 1,
        teacherId: _selectedTeacherId,
        teacherName: _selectedTeacherName,
      );

      if (plans.isEmpty) {
        throw Exception('A IA não retornou nenhum plano válido.');
      }
      
      debugPrint("Geração concluída com sucesso! Qtd de planos: ${plans.length}");
        
      bool saveError = false;
      for (int i = 0; i < plans.length; i++) {
        try {
          await DatabaseHelper.instance
              .insertLessonPlan(plans[i], customId: plans[i].id)
              .timeout(const Duration(seconds: 8));
        } catch (e) {
          saveError = true;
          debugPrint("Erro ao salvar plano no banco de dados (timeout/auth): $e");
        }
      }

      await _loadTeacherPlans();
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        if (saveError) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sequência gerada, mas não salva permanentemente (erro de banco). Exibindo localmente!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                count == 1
                    ? 'Aula gerada com sucesso para $_selectedTeacherName!'
                    : 'Sequência de $count aulas gerada com sucesso para $_selectedTeacherName!',
              ),
            ),
          );
        }
        
        try {
          if (widget.onPlanGenerated != null) {
            widget.onPlanGenerated!(plans.first);
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        } catch (navErr) {
          debugPrint("Erro ao navegar após geração: $navErr");
        }
      }
    } catch (e) {
      debugPrint("Erro em _gerarAula: $e");
      if (mounted) {
        final detail = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível gerar a aula. $detail'),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(label: 'Tentar de novo', onPressed: _gerarAula),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getSequenceStepLabel(int step, int total) {
    if (total == 1) return 'Aula Completa (Introdução, História, Quiz, Dinâmica e Oração)';
    if (step == 1) return 'Introdução ao Tema e Base Bíblica';
    if (step == total) return 'Consolidação da Verdade Central e Prática';
    if (step == 2) return 'Desenvolvimento da Narrativa Bíblica';
    if (step == 3) return 'Aprofundamento Teológico e Vivência';
    return 'Continuação da Série Pedagógica';
  }

  Widget _buildSequencePreviewBox(int count) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DsColors.primaryBlue.withOpacity(0.18)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: const Icon(Icons.view_timeline_rounded, size: 18, color: DsColors.primaryBlue),
          title: Text(
            count == 1
                ? 'Ver estrutura de 1 Aula Individual'
                : 'Ver sequência de $count Aulas para $_selectedTeacherName',
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          children: List.generate(count, (index) {
            final stepNum = index + 1;
            return Padding(
              padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 68,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: DsColors.primaryBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Aula $stepNum/$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _getSequenceStepLabel(stepNum, count),
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSavedSequencesSection() {
    if (_loadingPlans) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_teacherPlans.isEmpty) {
      return const SizedBox.shrink();
    }

    // Agrupa planos por seriesId (ou individual se seriesId for nulo)
    final Map<String, List<LessonPlan>> grouped = {};
    for (final plan in _teacherPlans) {
      final key = plan.seriesId.isNotEmpty
          ? plan.seriesId
          : 'single_${plan.id ?? plan.title}';
      grouped.putIfAbsent(key, () => []).add(plan);
    }

    // Garante que cada grupo esteja ordenado de Aula 1 até Aula N
    for (final list in grouped.values) {
      list.sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFBFDBFE), width: 1.5),
        ),
        child: ExpansionTile(
          leading: const Icon(Icons.view_list_rounded, color: DsColors.primaryBlue),
          iconColor: DsColors.primaryBlue,
          collapsedIconColor: DsColors.primaryBlue,
          title: Text(
            'Acessar Aulas Salvas de $_selectedTeacherName (${_teacherPlans.length})',
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          subtitle: const Text(
            'Toque para ver a sequência, estudar ou excluir aulas',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: grouped.entries.map((entry) {
                  final lessons = entry.value;
                  final first = lessons.first;
                  final total = lessons.length;
                  final seriesTitle = first.seriesTheme.isNotEmpty
                      ? first.seriesTheme
                      : first.title;
                  final teacherLabel = first.teacherName.isNotEmpty
                      ? first.teacherName
                      : _selectedTeacherName;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                lessons.length > 1 ? 'Sequência de ${lessons.length} Aulas' : 'Aula Individual',
                                style: const TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: DsColors.primaryBlue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Prof: $teacherLabel',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            if (first.seriesId.isNotEmpty && lessons.length > 1)
                              IconButton(
                                tooltip: 'Excluir série inteira',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 20),
                                onPressed: () async {
                                  await DatabaseHelper.instance.deleteLessonSeries(first.seriesId);
                                  await _loadTeacherPlans();
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tema: $seriesTitle',
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(lessons.length, (idx) {
                          final plan = lessons[idx];
                          final stepNum = idx + 1;
                          return Container(
                            margin: EdgeInsets.only(bottom: idx == lessons.length - 1 ? 0 : 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: DsColors.primaryBlue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$stepNum/$total',
                                        style: const TextStyle(
                                          fontFamily: 'Fredoka',
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        plan.title,
                                        style: const TextStyle(
                                          fontFamily: 'Fredoka',
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    if (plan.id != null)
                                      IconButton(
                                        tooltip: 'Excluir aula',
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                        onPressed: () async {
                                          await DatabaseHelper.instance.deleteLessonPlan(plan.id!);
                                          await _loadTeacherPlans();
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  plan.keyVerse,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TeacherPreparationScreen(
                                              plan: plan,
                                              onStartClass: () {
                                                if (widget.onPlanGenerated != null) {
                                                  widget.onPlanGenerated!(plan);
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.school_rounded, size: 14),
                                      label: const Text(
                                        'Estudar',
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
                                        if (widget.onPlanGenerated != null) {
                                          widget.onPlanGenerated!(plan);
                                        }
                                      },
                                      icon: const Icon(Icons.play_arrow_rounded, size: 15),
                                      label: const Text(
                                        'Ministrar',
                                        style: TextStyle(fontFamily: 'Fredoka', fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: Size.zero,
                                        backgroundColor: DsColors.primaryBlue,
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
  }

  @override
  Widget build(BuildContext context) {
    final int selectedCount = int.tryParse(_selectedAulas) ?? 4;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Planejar Série Mensal', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ) : null,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner do Assistente Lúdico
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    const MascotWidget(pose: MascotPose.front, width: 64, height: 80),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Planejador de Séries por Professor!',
                            style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Cada professor possui suas próprias aulas separadas. Ao escolher 4 aulas, a sequência completa fica organizada da Aula 1 à Aula 4.',
                            style: TextStyle(fontFamily: 'Nunito', color: Color(0xFF1E40AF), fontSize: 12.5, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Formulário de Configuração
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuração da Série e Professor',
                      style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 12),

                    // Seletor de Professor (para Coordenador/Admin) ou Identificação fixa (para Professor logado)
                    if (_isCoordinator && _availableTeachers.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: DropdownButtonFormField<String>(
                          value: _availableTeachers.any((t) => t['id'] == _selectedTeacherId)
                              ? _selectedTeacherId
                              : _availableTeachers.first['id'],
                          style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: Color(0xFF1E293B)),
                          decoration: InputDecoration(
                            labelText: 'Professor(a) Responsável pelas Aulas',
                            labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                            prefixIcon: const Icon(Icons.person_pin_rounded, size: 20, color: DsColors.primaryBlue),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DsColors.primaryBlue, width: 2)),
                          ),
                          items: _availableTeachers.map((teacher) {
                            return DropdownMenuItem<String>(
                              value: teacher['id'],
                              child: Text(teacher['name'] ?? 'Professor'),
                            );
                          }).toList(),
                          onChanged: (newId) {
                            if (newId != null) {
                              final found = _availableTeachers.firstWhere(
                                (t) => t['id'] == newId,
                                orElse: () => {'id': newId, 'name': 'Professor'},
                              );
                              setState(() {
                                _selectedTeacherId = newId;
                                _selectedTeacherName = found['name']!;
                              });
                              _loadTeacherPlans();
                            }
                          },
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_rounded, size: 18, color: DsColors.primaryBlue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Aulas exclusivas de: $_selectedTeacherName',
                                style: const TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    TextField(
                      controller: _temaController,
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Tema Principal da Sequência',
                        labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                        hintText: 'Ex: A Coragem de Davi, Arca de Noé',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: const Icon(Icons.lightbulb_rounded, size: 20, color: AppColors.amareloSol),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DsColors.primaryBlue, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedIdade,
                            style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: Color(0xFF1E293B)),
                            decoration: InputDecoration(
                              labelText: 'Faixa Etária',
                              labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DsColors.primaryBlue, width: 2)),
                            ),
                            items: _idades.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedIdade = newValue;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedAulas,
                            style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: Color(0xFF1E293B)),
                            decoration: InputDecoration(
                              labelText: 'Qtd de Aulas',
                              labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DsColors.primaryBlue, width: 2)),
                            ),
                            items: _aulas.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text('$value ${value == '1' ? 'aula' : 'aulas (sequência)'}'),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedAulas = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    // Demonstração visual imediata da sequência de aulas escolhida (ex: 4 aulas)
                    _buildSequencePreviewBox(selectedCount),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text(
                            'Gerando a sequência de aulas... isto pode levar até 2 minutos.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _gerarAula,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DsColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                        label: Text(
                          selectedCount == 1
                              ? 'Gerar 1 Aula para $_selectedTeacherName'
                              : 'Gerar Sequência de $selectedCount Aulas',
                          style: const TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

              // Lista de sequências e aulas salvas separadas para o professor selecionado
              _buildSavedSequencesSection(),
            ],
          ),
        ),
      ),
    );
  }
}
