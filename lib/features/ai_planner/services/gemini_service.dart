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
      return "\nIMPORTANTE TURMA MISTA: Você deve gerar um núcleo compartilhado (Mesma passagem, mesmo versículo) mas separar a atividade principal em estações (stations) para diferentes faixas. A estação '4-6' deve ter conteúdo 100% sensorial, motor, com texturas e gestos corporais, evitando abstração. As estações '7-8' e '9-11' devem ter conteúdo reflexivo com base no núcleo compartilhado. A aplicação deve surgir somente depois da compreensão da Verdade Central e deve representar uma implicação legítima dela. Nunca transformar personagem bíblico em mero exemplo de 'seja como ele'. A flag 'supportsTeams' deve ser false se houver conteúdo de acolhimento sensorial.";
    } else if (profile.minAge < 4) {
      return "\nIMPORTANTE: Como é para Berçário/Maternal (0-3 anos), o plano deve focar 100% em estímulos visuais, sensoriais e músicas! Troque perguntas complexas por dicas de como fazer sons ou toques, e a dinâmica deve ser muito física/sensorial. Manter a versão curta, altamente sensorial, com onomatopéias (ex: 'pata-pata') e instruções de gestos corporais em CAIXA ALTA (ex: [BATER PALMAS]). stations não se aplicam tanto, mas retorne no formato JSON exigido.";
    } else if (profile.minAge >= 7) {
      return "\nIMPORTANTE: Como é para 7-11 anos (Primários/Juniores), a História NÃO pode ser reduzida a tópicos curtos. Gere uma NARRATIVA COMPLETA de 4 a 5 blocos, contendo obrigatoriamente:\n1. Contexto histórico.\n2. Conflito/tensão.\n3. O milagre.\n4. Reflexão teológica. A aplicação deve surgir somente depois da compreensão da Verdade Central e deve representar uma implicação legítima dela. Nunca transformar personagem bíblico em mero exemplo de 'seja como ele'. supportsTeams deve ser true se couber jogo competitivo.";
    }
    return "\nIMPORTANTE: Como é para 4-7 anos, equilibre atividades físicas/sensoriais simples com início de compreensão bíblica. A aplicação deve surgir somente depois da compreensão da Verdade Central e deve representar uma implicação legítima dela. Nunca transformar personagem bíblico em mero exemplo de 'seja como ele'. Use dinâmicas de movimento.";
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

HIERARQUIA OBRIGATÓRIA DA GERAÇÃO:
Seu processo de geração de cada plano de aula DEVE seguir estritamente esta ordem de prioridade lógica:
1. TEXTO BÍBLICO (leitura exata da passagem).
2. BIBLICAL CORE (exegese e estruturação hermenêutica).
3. VERDADE CENTRAL X (definição da verdade central teológica única).
4. ADAPTAÇÃO PEDAGÓGICA (ajuste de linguagem por faixa etária).
5. CONTEÚDO DA AULA (criação dos cartões de estações, dinâmicas, orações, história, etc., derivados de X).

Você NÃO deve partir primeiro de dinâmica, moral, comportamento desejado pelas crianças, jogo ou faixa etária. Primeiro deve compreender e estruturar a passagem bíblica.

PRINCÍPIO GOVERNANTE:
Simplificar a linguagem, nunca substituir a mensagem do texto.
A 'centralTruth' é única para toda a aula. As faixas etárias nas estações ('stations') podem alterar o vocabulário, detalhes de execução, exemplos práticos e forma de interação, mas NÃO podem alterar a 'centralTruth', o significado teológico da passagem, as ações atribuídas aos personagens ou os limites definidos em 'textDoesNotSay'.

PROTEÇÕES NARRATIVAS:
A história e os tópicos da história ('storyTopics') não podem inventar pensamentos dos personagens, emoções, diálogos ou detalhes de cenário que estejam ausentes do texto bíblico original. Mantenha fidelidade factual e textual estrita.

PROTEÇÕES CONTRA MORALISMO:
A aplicação prática nas estações, história ou atividades deve surgir somente depois da compreensão da Verdade Central e deve representar uma implicação legítima dela. Nunca transforme um personagem bíblico em um mero exemplo comportamental ('seja bom como fulano', 'faça como ciclano').

CONEXÃO CANÔNICA / CRISTOLÓGICA (SE HOUVER):
Não force conexões artificiais com Cristo em todas as aulas. Se houver uma conexão canônica legítima, apresente-a na estrutura:
TEXTO original -> DESENVOLVIMENTO CANÔNICO -> CONCLUSÃO em Cristo.

FREIO HERMENÊUTICO E REVISÃO INTERNA OBRIGATÓRIA:
Antes de produzir e devolver o JSON final, você DEVE revisar internamente todos os campos gerados ('objective', 'storyTopics', 'questions', 'stations', 'dynamicActivity', 'prayer') contra os limites de ('centralTruth', 'textSays', 'textAllowsToConclude', 'textDoesNotSay'). 
Se houver qualquer violação ou se alguma ideia vetada em 'textDoesNotSay' reaparecer em qualquer parte da aula (como moralismos comportamentais ou técnicas de silêncio acústico), você DEVE corrigir e reescrever o conteúdo antes de retornar o JSON final.

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
    "biblicalCore": {
      "passage": "referência bíblica exata (ex: 1 Samuel 3:1-21)",
      "centralTruth": "a verdade teológica central e única da passagem",
      "textSays": [
        "fato literal 1 afirmado no texto",
        "fato literal 2 afirmado no texto"
      ],
      "textAllowsToConclude": [
        "conclusão teológica/prática legítima derivada diretamente do texto",
        "outra conclusão legítima"
      ],
      "textDoesNotSay": [
        "ideia errônea ou moralista que o texto NÃO diz ou não apoia",
        "outra extrapolação a ser evitada"
      ],
      "historicalContext": [
        "detalhe relevante do contexto histórico/cultural da passagem"
      ],
      "theologicalCore": "explicação do coração teológico da passagem para o estudo do professor"
    },
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

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');
    
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
              biblicalCore: data['biblicalCore'] != null ? BiblicalCore.fromMap(data['biblicalCore'] as Map<String, dynamic>) : null,
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
