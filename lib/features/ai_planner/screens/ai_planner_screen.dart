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
  final ValueChanged<LessonPlan>? onPlanGenerated;

  const AiPlannerScreen({super.key, this.onPlanGenerated});

  @override
  State<AiPlannerScreen> createState() => _AiPlannerScreenState();
}

class _AiPlannerScreenState extends State<AiPlannerScreen> {
  final _temaController = TextEditingController();

  String _selectedIdade = '4-7 anos';
  final List<String> _idades = ['0-4 anos', '4-7 anos', '7-11 anos', 'Turma Mista (4 a 11 anos)'];
  
  String _selectedAulas = '4';
  final List<String> _aulas = ['1', '2', '3', '4', '5'];
  
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
      final int count = int.tryParse(_selectedAulas) ?? 4;
      final plans = await _geminiService.generateMonthlySeries(
        _temaController.text,
        _selectedIdade,
        count,
      ).timeout(const Duration(seconds: 35), onTimeout: () {
        throw Exception("O Gemini demorou muito para responder (Timeout).");
      });
        
      bool saveError = false;
      for (var plan in plans) {
        try {
          await DatabaseHelper.instance.insertLessonPlan(plan).timeout(const Duration(seconds: 8));
        } catch (e) {
          saveError = true;
          debugPrint("Erro ao salvar plano no banco de dados (timeout/auth): $e");
        }
      }
      
      if (mounted) {
        if (saveError) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aula gerada, mas não salva permanentemente (erro de banco). Exibindo localmente!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Série de $count aulas gerada com sucesso! 🎉')),
          );
        }
        if (widget.onPlanGenerated != null && plans.isNotEmpty) {
          widget.onPlanGenerated!(plans.first);
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar aula: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            'Planejador de Séries Mensais!',
                            style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'A inteligência artificial vai estruturar uma série completa de aulas com base no tema escolhido para a sua turma.',
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
                                child: Text('$value ${value == '1' ? 'aula' : 'aulas'}'),
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
