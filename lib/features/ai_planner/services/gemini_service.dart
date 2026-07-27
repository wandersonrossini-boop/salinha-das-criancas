import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_plan.dart';

class GeminiService {
  Future<LessonPlan> generateLessonPlan(String theme, String ageGroup, String duration) async {
    String apiKey = '';
    
    try {
      final doc = await FirebaseFirestore.instance.collection('config').doc('gemini').get();
      if (doc.exists && doc.data() != null) {
        apiKey = doc.data()!['api_key'] ?? '';
      }
    } catch (e) {
      // Ignorar e tentar SharedPreferences ou fallback
    }

    if (apiKey.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      apiKey = prefs.getString('gemini_api_key') ?? '';
    }

    if (apiKey.isEmpty) {
      // Fallback para chave embutida no código
      const String fallbackKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
      if (fallbackKey.isNotEmpty) {
        apiKey = fallbackKey;
      } else {
        throw Exception('A chave da IA não foi configurada pelo Administrador. Peça para o Admin configurar a chave no painel.');
      }
    }

    bool isBaby = ageGroup.toLowerCase().contains('berçário') || 
                  ageGroup.toLowerCase().contains('maternal') || 
                  ageGroup.contains('0') || 
                  ageGroup.contains('1') || 
                  ageGroup.contains('2') || 
                  ageGroup.contains('3');

    String specialInstructions = isBaby 
        ? "\nIMPORTANTE: Como é para Berçário/Maternal (0-3 anos), o plano deve focar 100% em estímulos visuais, sensoriais e músicas! Troque perguntas complexas por dicas de como fazer sons ou toques, e a dinâmica deve ser muito física/sensorial."
        : "";

    final prompt = '''
Você é um especialista em ministério infantil cristão. 
Crie um plano de aula dinâmico e engajador para crianças.
Tema: $theme
Faixa Etária: $ageGroup
Tempo Estimado: $duration$specialInstructions

RETORNE APENAS UM JSON VÁLIDO EXATAMENTE NESTE FORMATO (sem formatação markdown como ```json):
{
  "objective": "objetivo da aula",
  "keyVerse": "versículo chave",
  "storyTopics": "tópicos resumidos da história em bullet points",
  "questions": [
    {
      "question": "pergunta do quiz",
      "options": ["A", "B", "C", "D"],
      "answer": "A"
    },
    {
      "question": "pergunta do quiz",
      "options": ["A", "B", "C", "D"],
      "answer": "A"
    },
    {
      "question": "pergunta do quiz",
      "options": ["A", "B", "C", "D"],
      "answer": "A"
    }
  ],
  "dynamicActivity": "explicação da dinâmica do dia",
  "prayer": "dicas e tópicos em formato de bullet points de como o professor deve guiar a oração final (não escreva a oração completa e engessada, apenas dicas de motivos de oração e como orar)"
}
''';

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=$apiKey');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [{'text': prompt}]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final String? responseText = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];

      if (responseText != null) {
        String cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> data = jsonDecode(cleanJson);
        
        return LessonPlan(
          title: theme,
          ageGroup: ageGroup,
          objective: data['objective'] ?? '',
          keyVerse: data['keyVerse'] ?? '',
          storyTopics: data['storyTopics'] ?? '',
          questions: data['questions'] is List ? jsonEncode(data['questions']) : (data['questions'] ?? ''),
          dynamicActivity: data['dynamicActivity'] ?? '',
          prayer: data['prayer'] ?? '',
        );
      } else {
        throw Exception('A resposta da IA foi nula.');
      }
    } else {
      throw Exception('Erro na API (Status ${response.statusCode}): ${response.body}');
    }
  }
}
