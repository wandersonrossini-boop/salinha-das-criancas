import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/db/database_helper.dart';
import '../services/gemini_service.dart';
import '../models/lesson_plan.dart';

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
        return AlertDialog(
          title: const Text('Configurar Gemini API'),
          content: TextField(
            controller: keyController,
            decoration: const InputDecoration(
              labelText: 'API Key',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await prefs.setString('gemini_api_key', keyController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chave salva com sucesso!')),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
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
        
      await DatabaseHelper.instance.insertLessonPlan(plan);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aula gerada e salva com sucesso! 🎉')),
        );
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assistente de IA', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Reduzido de 24
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Prepare sua aula em segundos!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary), // Reduzido de 24
              ),
              const SizedBox(height: 6),
              const Text(
                'A inteligência artificial vai estruturar o plano ideal para a sua salinha.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20), // Reduzido de 32
              TextField(
                controller: _temaController,
                decoration: const InputDecoration(
                  labelText: 'Tema Principal (Ex: A Coragem de Davi)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedIdade,
                      decoration: const InputDecoration(
                        labelText: 'Faixa Etária',
                        border: OutlineInputBorder(),
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
                      decoration: const InputDecoration(
                        labelText: 'Tempo',
                        border: OutlineInputBorder(),
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
              const SizedBox(height: 32), // Em vez de Spacer()
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _gerarAula,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.azulCeleste,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.auto_awesome, size: 20),
                        label: const Text('Gerar Aula com IA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
