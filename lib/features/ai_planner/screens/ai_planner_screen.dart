import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/db/database_helper.dart';
import '../services/gemini_service.dart';
import '../models/lesson_plan.dart';
import '../../../core/components/mascot/mascot_widget.dart';
import '../../../core/components/mascot/mascot_assets.dart';
import '../../../core/design_system/colors.dart';

class AiPlannerScreen extends StatefulWidget {
  const AiPlannerScreen({super.key});

  @override
  State<AiPlannerScreen> createState() => _AiPlannerScreenState();
}

class _AiPlannerScreenState extends State<AiPlannerScreen> {
  final _temaController = TextEditingController();

  String _selectedIdade = '4-7 anos';
  final List<String> _idades = ['0-4 anos', '4-7 anos', '7-11 anos'];
  
  String _selectedTempo = '45 min';
  final List<String> _tempos = ['30 min', '45 min', '60 min', '90 min'];
  
  bool _isLoading = false;
  final GeminiService _geminiService = GeminiService();

  void _showApiKeyModal() async {
    final prefs = await SharedPreferences.getInstance();
    final currentKey = prefs.getString('gemini_api_key') ?? '';
    final keyController = TextEditingController(text: currentKey);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Configurar Gemini API ⚙️', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: keyController,
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar', style: TextStyle(fontFamily: 'Fredoka', color: Color(0xFF64748B))),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await prefs.setString('gemini_api_key', keyController.text.trim());
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chave salva com sucesso! 🎉')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: DsColors.primaryBlue, foregroundColor: Colors.white),
                        child: const Text('Salvar', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Future<void> _gerarAula() async {
    if (_temaController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final plan = await _geminiService.generateLessonPlan(
        _temaController.text,
        _selectedIdade,
        _selectedTempo,
      );

      if (mounted) {
        _showGeneratedPlanModal(plan);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar aula: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showGeneratedPlanModal(LessonPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Plano Gerado com Sucesso! 🎉',
                  style: TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tema: ${plan.title}', style: const TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.azulCeleste)),
                    const SizedBox(height: 8),
                    Text('Objetivo: ${plan.objective}', style: const TextStyle(fontFamily: 'Nunito', fontSize: 14)),
                    const SizedBox(height: 12),
                    Text('Versículo: ${plan.keyVerse}', style: const TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
                    const SizedBox(height: 12),
                    const Text('Tópicos da História:', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(plan.storyTopics, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13.5)),
                    const SizedBox(height: 12),
                    const Text('Dinâmica do Dia:', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(plan.dynamicActivity, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await DatabaseHelper.instance.insertLessonPlan(plan);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🎉 Aula definida como Aula de Hoje e salva no banco!')),
                  );
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.rocket_launch_rounded),
              label: const Text('🚀 Definir como Aula de Hoje', style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Assistente de IA', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
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
                            'Prepare sua aula em segundos!',
                            style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'A inteligência artificial vai estruturar o plano ideal de quebra-gelo, história, quiz e dinâmica para a sua salinha.',
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
                      'O que vamos ensinar hoje?',
                      style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _temaController,
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Tema Principal',
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
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'Davi e Golias',
                          'Arca de Noé',
                          'Parábola do Semeador',
                          'Armadura de Deus',
                          'Nascimento de Jesus',
                        ].map((suggested) => Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ActionChip(
                            label: Text(suggested, style: const TextStyle(fontFamily: 'Fredoka', fontSize: 11.5)),
                            backgroundColor: Colors.blue.shade50,
                            side: BorderSide(color: Colors.blue.shade200),
                            onPressed: () {
                              setState(() {
                                _temaController.text = suggested;
                                _temaController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: suggested.length),
                                );
                              });
                            },
                          ),
                        )).toList(),
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
                            value: _selectedTempo,
                            style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: Color(0xFF1E293B)),
                            decoration: InputDecoration(
                              labelText: 'Tempo de Aula',
                              labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DsColors.primaryBlue, width: 2)),
                            ),
                            items: _tempos.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedTempo = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
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
                        label: const Text('Gerar Aula com IA', style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
