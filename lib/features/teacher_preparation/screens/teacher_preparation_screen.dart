import 'package:flutter/material.dart';
import '../../ai_planner/models/lesson_plan.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/design_system/colors.dart';
import '../../../core/design_system/radius.dart';
import '../../../core/db/database_helper.dart';

class TeacherPreparationScreen extends StatefulWidget {
  final LessonPlan plan;
  final VoidCallback onStartClass;

  const TeacherPreparationScreen({
    super.key,
    required this.plan,
    required this.onStartClass,
  });

  @override
  State<TeacherPreparationScreen> createState() => _TeacherPreparationScreenState();
}

class _TeacherPreparationScreenState extends State<TeacherPreparationScreen> {
  late LessonPlan _currentPlan;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentPlan = widget.plan;
  }

  Future<void> _saveChanges(LessonPlan updatedPlan) async {
    setState(() {
      _isSaving = true;
      _currentPlan = updatedPlan;
    });

    try {
      await DatabaseHelper.instance.updateLessonPlan(updatedPlan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alterações salvas.'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _editSection(String title, Map<String, dynamic> initialValues, Function(Map<String, String>) onSave) {
    final Map<String, TextEditingController> controllers = {};
    initialValues.forEach((key, val) {
      if (val is List<String>) {
        controllers[key] = TextEditingController(text: val.join('\n'));
      } else {
        controllers[key] = TextEditingController(text: val?.toString() ?? '');
      }
    });

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Editar $title',
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...controllers.entries.map((entry) {
                    final label = entry.key;
                    final controller = entry.value;
                    final isList = initialValues[label] is List<String>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: TextField(
                        controller: controller,
                        maxLines: isList ? 6 : 2,
                        minLines: 1,
                        decoration: InputDecoration(
                          labelText: isList ? '$label (1 item por linha)' : label,
                          alignLabelWithHint: true,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar', style: TextStyle(fontFamily: 'Fredoka')),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final Map<String, String> results = {};
                          controllers.forEach((k, ctrl) {
                            results[k] = ctrl.text.trim();
                          });
                          onSave(results);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DsColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Salvar', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _editEstudar() {
    final core = _currentPlan.biblicalCore;
    if (core == null) return;

    _editSection(
      'ESTUDAR',
      {
        'Passagem': core.passage,
        'O texto diz': core.textSays,
        'Contexto histórico': core.historicalContext,
      },
      (results) {
        final newSays = results['O texto diz']!.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        final newCtx = results['Contexto histórico']!.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

        final updatedCore = BiblicalCore(
          passage: results['Passagem']!,
          centralTruth: core.centralTruth,
          textSays: newSays,
          textAllowsToConclude: core.textAllowsToConclude,
          textDoesNotSay: core.textDoesNotSay,
          historicalContext: newCtx,
          theologicalCore: core.theologicalCore,
        );

        final updatedPlan = LessonPlan(
          id: _currentPlan.id,
          title: _currentPlan.title,
          ageGroup: _currentPlan.ageGroup,
          objective: _currentPlan.objective,
          keyVerse: _currentPlan.keyVerse,
          storyTopics: _currentPlan.storyTopics,
          questions: _currentPlan.questions,
          dynamicActivity: _currentPlan.dynamicActivity,
          prayer: _currentPlan.prayer,
          ageProfile: _currentPlan.ageProfile,
          supportsTeams: _currentPlan.supportsTeams,
          stations: _currentPlan.stations,
          biblicalCore: updatedCore,
        );

        _saveChanges(updatedPlan);
      },
    );
  }

  void _editCompreender() {
    final core = _currentPlan.biblicalCore;
    if (core == null) return;

    _editSection(
      'COMPREENDER',
      {
        'Verdade Central': core.centralTruth,
        'Coração Teológico': core.theologicalCore,
        'Permite concluir': core.textAllowsToConclude,
        'Cuidado ao ensinar': core.textDoesNotSay,
      },
      (results) {
        final newConclude = results['Permite concluir']!.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        final newSaysNot = results['Cuidado ao ensinar']!.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

        final updatedCore = BiblicalCore(
          passage: core.passage,
          centralTruth: results['Verdade Central']!,
          textSays: core.textSays,
          textAllowsToConclude: newConclude,
          textDoesNotSay: newSaysNot,
          historicalContext: core.historicalContext,
          theologicalCore: results['Coração Teológico']!,
        );

        final updatedPlan = LessonPlan(
          id: _currentPlan.id,
          title: _currentPlan.title,
          ageGroup: _currentPlan.ageGroup,
          objective: _currentPlan.objective,
          keyVerse: _currentPlan.keyVerse,
          storyTopics: _currentPlan.storyTopics,
          questions: _currentPlan.questions,
          dynamicActivity: _currentPlan.dynamicActivity,
          prayer: _currentPlan.prayer,
          ageProfile: _currentPlan.ageProfile,
          supportsTeams: _currentPlan.supportsTeams,
          stations: _currentPlan.stations,
          biblicalCore: updatedCore,
        );

        _saveChanges(updatedPlan);
      },
    );
  }

  void _editAdaptar() {
    _editSection(
      'ADAPTAR',
      {
        'Objetivo da Aula': _currentPlan.objective,
      },
      (results) {
        final updatedPlan = LessonPlan(
          id: _currentPlan.id,
          title: _currentPlan.title,
          ageGroup: _currentPlan.ageGroup,
          objective: results['Objetivo da Aula']!,
          keyVerse: _currentPlan.keyVerse,
          storyTopics: _currentPlan.storyTopics,
          questions: _currentPlan.questions,
          dynamicActivity: _currentPlan.dynamicActivity,
          prayer: _currentPlan.prayer,
          ageProfile: _currentPlan.ageProfile,
          supportsTeams: _currentPlan.supportsTeams,
          stations: _currentPlan.stations,
          biblicalCore: _currentPlan.biblicalCore,
        );

        _saveChanges(updatedPlan);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final core = _currentPlan.biblicalCore;
    final hasCore = core != null;

    return Scaffold(
      backgroundColor: DsColors.background,
      appBar: AppBar(
        title: const Text(
          'Preparação do Professor',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Aviso de Inteligência Artificial no topo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF1F5F9),
              child: const Text(
                'Conteúdo estruturado com apoio de IA. Revise as referências e o conteúdo antes de ministrar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            if (_isSaving)
              const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(DsColors.primaryBlue),
              ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cabeçalho da lição
                    Text(
                      _currentPlan.title,
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasCore ? core.passage : _currentPlan.keyVerse,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: DsColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 20),

                    if (!hasCore) ...[
                      // Modo Retrocompatibilidade
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: DsRadius.large,
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Aviso',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Esta aula foi criada antes do novo modo de preparação.',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ADAPTAR Legado
                      _buildSectionHeader('ADAPTAR', 'Como ensinar essa lição à turma?', onEdit: _editAdaptar),
                      const SizedBox(height: 12),
                      _buildInfoBlock('Objetivo da Aula', _currentPlan.objective),
                      if (_currentPlan.stations.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Estações Pedagógicas',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._currentPlan.stations.map((s) => _buildStationCard(s)),
                      ],
                    ] else ...[
                      // --- ESTUDAR ---
                      _buildSectionHeader('1. ESTUDAR', 'O que está acontecendo no texto?', onEdit: _editEstudar),
                      const SizedBox(height: 16),
                      if (core.textSays.isNotEmpty)
                        _buildBulletList('O texto bíblico diz:', core.textSays),
                      if (core.historicalContext.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildContextCard('Contexto para entender', core.historicalContext),
                      ],
                      const SizedBox(height: 24),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 20),

                      // --- COMPREENDER ---
                      _buildSectionHeader('2. COMPREENDER', 'O que esta passagem está ensinando?', onEdit: _editCompreender),
                      const SizedBox(height: 20),
                      
                      // Verdade Central em destaque
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: DsRadius.large,
                          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'VERDADE CENTRAL',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              core.centralTruth,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (core.theologicalCore.isNotEmpty)
                        _buildInfoBlock('Coração Teológico', core.theologicalCore),
                      
                      if (core.textAllowsToConclude.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildBulletList('O que o texto permite concluir:', core.textAllowsToConclude),
                      ],

                      if (core.textDoesNotSay.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildWarningCard('Cuidado ao ensinar', core.textDoesNotSay),
                      ],

                      const SizedBox(height: 24),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 20),

                      // --- ADAPTAR ---
                      _buildSectionHeader('3. ADAPTAR', 'Como ensinar essa verdade à turma?', onEdit: _editAdaptar),
                      const SizedBox(height: 16),
                      _buildInfoBlock('Objetivo da Aula', _currentPlan.objective),
                      if (_currentPlan.stations.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Estações Pedagógicas por Faixa Etária',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._currentPlan.stations.map((s) => _buildStationCard(s)),
                      ],
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            
            // Rodapé com o botão fixo de começar aula
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onStartClass();
                  },
                  icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white),
                  label: const Text(
                    'COMEÇAR AULA',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DsColors.primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, {VoidCallback? onEdit}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DsColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        if (onEdit != null)
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF3B82F6)),
            label: const Text(
              'Editar',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B82F6),
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoBlock(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            height: 1.4,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletList(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(' •  ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildContextCard(String title, List<String> contextLines) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: DsRadius.large,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 10),
          ...contextLines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text(
                  line,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF64748B),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildWarningCard(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        borderRadius: DsRadius.large,
        border: Border.all(color: const Color(0xFFF3E8FF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline_rounded, color: Color(0xFF8B5CF6), size: 18),
              SizedBox(width: 8),
              Text(
                'Cuidado ao Ensinar',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6D28D9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(' -  ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          height: 1.35,
                          color: Color(0xFF6D28D9),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildStationCard(MixedAgeStation station) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: DsRadius.large,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Faixa ${station.ageBand}',
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    station.duration,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            station.description,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Materiais: ${station.materials.join(', ')}',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
