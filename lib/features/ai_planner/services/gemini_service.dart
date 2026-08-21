import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_plan.dart';
import '../models/classroom_age_profile.dart';
import '../../../core/utils/safe_converters.dart';

class GeminiService {
  ClassroomAgeProfile _parseAgeGroup(String ageGroup) {
    if (ageGroup.toLowerCase().contains('turma mista') || ageGroup.contains('4 a 11') || ageGroup.contains('4-11')) {
      return ClassroomAgeProfile(
        minAge: 4,
        maxAge: 11,
        isMixedAge: true,
        activeBands: ['4-6', '7-8', '9-11'],
      );
    } else if (ageGroup.contains('0-4') || ageGroup.toLowerCase().contains('berçário') || ageGroup.toLowerCase().contains('maternal')) {
      return ClassroomAgeProfile(
        minAge: 0,
        maxAge: 4,
        isMixedAge: false,
        activeBands: ['0-4'],
      );
    } else if (ageGroup.contains('4-7') || ageGroup.contains('4-6')) {
      return ClassroomAgeProfile(
        minAge: 4,
        maxAge: 7,
        isMixedAge: false,
        activeBands: ['4-7'],
      );
    } else {
      return ClassroomAgeProfile(
        minAge: 7,
        maxAge: 11,
        isMixedAge: false,
        activeBands: ['7-11'],
      );
    }
  }

  String _getMethodologicalInstructions(ClassroomAgeProfile profile) {
    if (profile.isMixedAge) {
      return "\nIMPORTANTE TURMA MISTA: Você deve gerar um núcleo compartilhado (Mesma passagem, mesmo versículo) mas separar a atividade principal em estações (stations) para diferentes faixas. A estação '4-6' deve ter conteúdo 100% sensorial, motor, com texturas e gestos corporais, evitando abstração. As estações '7-8' e '9-11' devem ter conteúdo reflexivo, dilemas éticos, estudos de caso e missões. A flag 'supportsTeams' deve ser false se houver conteúdo de acolhimento sensorial.";
    } else if (profile.minAge < 4) {
      return "\nIMPORTANTE: Como é para Berçário/Maternal (0-3 anos), o plano deve focar 100% em estímulos visuais, sensoriais e músicas! Troque perguntas complexas por dicas de como fazer sons ou toques, e a dinâmica deve ser muito física/sensorial. Manter a versão curta, altamente sensorial, com onomatopéias (ex: 'pata-pata') e instruções de gestos corporais em CAIXA ALTA (ex: [BATER PALMAS]). stations não se aplicam tanto, mas retorne no formato JSON exigido.";
    } else if (profile.minAge >= 7) {
      return "\nIMPORTANTE: Como é para 7-11 anos (Primários/Juniores), a História NÃO pode ser reduzida a tópicos curtos. Gere uma NARRATIVA COMPLETA de 4 a 5 blocos, contendo obrigatoriamente:\n1. Contexto histórico.\n2. Conflito/tensão.\n3. O milagre.\n4. Reflexão teológica. Inclua dilemas éticos, resolução de casos. supportsTeams deve ser true se couber jogo competitivo.";
    }
    return "\nIMPORTANTE: Como é para 4-7 anos, equilibre atividades físicas/sensoriais simples com início de compreensão moral. Use dinâmicas de movimento.";
  }

  Future<LessonPlan> generateLessonPlan(String theme, String ageGroup, String duration) async {
    // Para aula individual, pedimos série de 1 sem injetar semântica de série mensal
    final results = await generateMonthlySeries(theme, ageGroup, 1, isIndividual: true);
    if (results.isEmpty) {
      throw Exception('A IA não retornou uma aula válida.');
    }
    return results.first;
  }

  Future<List<LessonPlan>> generateMonthlySeries(String theme, String ageGroup, int count, {bool isIndividual = false}) async {
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
      const String fallbackKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
      if (fallbackKey.isNotEmpty) {
        apiKey = fallbackKey;
      } else {
        throw Exception('A chave da IA não foi configurada pelo Administrador.');
      }
    }

    final ageProfile = _parseAgeGroup(ageGroup);
    String specialInstructions = _getMethodologicalInstructions(ageProfile);
    
    String countInstruction = isIndividual 
      ? 'Crie um plano de aula dinâmico e engajador para crianças.' 
      : 'Crie uma série de \$count aulas dinâmicas e engajadoras.';

    final prompt = '''
Você é um especialista em ministério infantil cristão. 
\$countInstruction
Tema\${isIndividual ? '' : ' da Série'}: \$theme
Faixa Etária: \$ageGroup
\$specialInstructions

RETORNE APENAS UM JSON VÁLIDO EXATAMENTE NESTE FORMATO (sem formatação markdown como ```json). Deve ser uma array de \$count objetos:
[
  {
    "title": "título criativo da aula (ex: Aula 1 - A Criação)",
    "objective": "objetivo da aula",
    "keyVerse": "versículo chave",
    "storyTopics": "tópicos resumidos da história em bullet points",
    "dynamicActivity": "resumo geral da atividade",
    "prayer": "dicas e tópicos em formato de bullet points para guiar a oração",
    "supportsTeams": true,
    "stations": [
      {
        "ageBand": "4-6",
        "duration": "15 min",
        "materials": ["item 1", "item 2"],
        "preparation": "como preparar o espaço",
        "executionSteps": ["passo 1", "passo 2"],
        "description": "descrição da estação para os menores"
      },
      {
        "ageBand": "7-11",
        "duration": "20 min",
        "materials": ["item 3"],
        "preparation": "como preparar para os maiores",
        "executionSteps": ["passo 1", "passo 2"],
        "description": "descrição do desafio ou reflexão"
      }
    ],
    "questions": [
      {
        "question": "pergunta do quiz",
        "options": ["A", "B", "C", "D"],
        "answer": "A",
        "ageMin": 4,
        "ageMax": 11,
        "difficulty": "facil",
        "type": "geral"
      }
    ]
  }
]
''';

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=\$apiKey');
    
    http.Response response;
    try {
      response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw Exception('A requisição para a IA excedeu o tempo limite de 30 segundos.');
    } catch (e) {
      throw Exception('Erro de conexão ao acessar a IA: \$e');
    }

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final String? responseText = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];

      if (responseText != null) {
        String cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
        dynamic decodedJson;
        try {
          decodedJson = jsonDecode(cleanJson);
        } catch (e) {
          throw Exception('A resposta da IA não é um JSON válido: \$e');
        }

        if (decodedJson is Map) {
          if (decodedJson['title'] == null || decodedJson['keyVerse'] == null || decodedJson['title'].toString().trim().isEmpty || decodedJson['keyVerse'].toString().trim().isEmpty) {
            throw Exception('A IA retornou um Objeto, mas faltaram os campos mínimos exigidos (title e keyVerse).');
          }
          decodedJson = [decodedJson]; // Envolve em lista
        }

        if (decodedJson is! List) {
          throw Exception('O formato esperado era uma Lista, mas a IA retornou um tipo incorreto.');
        }

        final List<dynamic> dataList = decodedJson;
        List<LessonPlan> validPlans = [];
        List<String> errors = [];
        
        for (int i = 0; i < dataList.length; i++) {
          final data = dataList[i];
          if (data == null || data is! Map) {
            errors.add('Índice \$i: Formato do item corrompido (não é Map).');
            continue;
          }
          if (data['title'] == null || data['keyVerse'] == null || data['title'].toString().trim().isEmpty || data['keyVerse'].toString().trim().isEmpty) {
            errors.add('Índice \$i: Campos mínimos ausentes ou vazios (title ou keyVerse).');
            continue;
          }
          
          try {
            validPlans.add(LessonPlan(
              title: data['title'].toString().trim(),
              ageGroup: ageGroup,
              objective: data['objective']?.toString() ?? '',
              keyVerse: data['keyVerse'].toString().trim(),
              storyTopics: data['storyTopics']?.toString() ?? '',
              questions: data['questions'] is List ? jsonEncode(data['questions']) : (data['questions']?.toString() ?? ''),
              dynamicActivity: data['dynamicActivity']?.toString() ?? '',
              prayer: data['prayer']?.toString() ?? '',
              ageProfile: ageProfile,
              supportsTeams: safeBool(data['supportsTeams'], fallback: false),
              stations: data['stations'] is List 
                  ? (data['stations'] as List).map((s) => MixedAgeStation.fromMap(s as Map<String, dynamic>)).toList() 
                  : [],
            ));
          } catch (e) {
            errors.add('Índice \$i: Erro ao instanciar LessonPlan (\$e).');
          }
        }

        if (validPlans.isEmpty) {
          throw Exception('Nenhum plano válido foi gerado. Erros encontrados: \${errors.join(" | ")}');
        }
        
        if (errors.isNotEmpty) {
          print('WARNING: Perda parcial de planos gerados. Erros: \${errors.join(" | ")}');
        }
        
        return validPlans;
      } else {
        throw Exception('A resposta da IA foi nula.');
      }
    } else {
      throw Exception('Erro na API (Status \${response.statusCode}): \${response.body}');
    }
  }
}
