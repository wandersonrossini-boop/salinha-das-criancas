import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_plan.dart';
import '../models/classroom_age_profile.dart';
import '../../../core/utils/safe_converters.dart';
import '../../../core/utils/emoji_stripper.dart';

class GeminiService {
  String _redact(Object error, String apiKey) {
    final text = error.toString();
    return apiKey.isEmpty ? text : text.replaceAll(apiKey, '***');
  }

  String _extractApiErrorDetail(String responseBody, String apiKey) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map && decoded['error'] is Map) {
        final err = decoded['error'] as Map;
        final status = err['status']?.toString() ?? '';
        final message = err['message']?.toString() ?? '';
        if (message.isNotEmpty) {
          return _redact(
            status.isNotEmpty ? '[$status] $message' : message,
            apiKey,
          );
        }
      }
    } catch (_) {
      // Fallback para o corpo bruto sanitizado se não for JSON padrão
    }
    return _redact(responseBody, apiKey);
  }

  ClassroomAgeProfile _parseAgeGroup(String ageGroup) {
    if (ageGroup.toLowerCase().contains('turma mista') || ageGroup.contains('4 a 11') || ageGroup.contains('4-11')) {
      return ClassroomAgeProfile(
        minAge: 4,
        maxAge: 11,
        isMixedAge: true,
        activeBands: ['4-7', '8-11'],
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
        minAge: 8,
        maxAge: 11,
        isMixedAge: false,
        activeBands: ['8-11'],
      );
    }
  }

  String _getMethodologicalInstructions(ClassroomAgeProfile profile) {
    if (profile.isMixedAge) {
      return "\nIMPORTANTE TURMA MISTA (4 a 11 anos): Você deve gerar um núcleo compartilhado (Mesma passagem, mesmo versículo) mas separar a atividade principal em duas estações (stations) para as faixas oficiais: '4-7' e '8-11'. A estação '4-7' deve ter conteúdo sensorial, motor e visual com gestos corporais e linguagem concreta. A estação '8-11' deve ter conteúdo reflexivo e colaborativo com base no núcleo compartilhado. A aplicação deve surgir somente depois da compreensão da Verdade Central e deve representar uma implicação legítima dela. Nunca transformar personagem bíblico em mero exemplo de 'seja como ele'.";
    } else if (profile.minAge >= 8) {
      return "\nIMPORTANTE: Como é para 8-11 anos, a História NÃO pode ser reduzida a tópicos curtos. Gere uma NARRATIVA COMPLETA de 4 a 5 blocos, contendo obrigatoriamente:\n1. Contexto histórico.\n2. Conflito/tensão.\n3. Ação de Deus na passagem.\n4. Reflexão teológica. Gere estação com ageBand '8-11' (e opcionalmente '4-7' para adaptação). A aplicação deve surgir somente depois da compreensão da Verdade Central e deve representar uma implicação legítima dela. Nunca transformar personagem bíblico em mero exemplo de 'seja como ele'. supportsTeams deve ser true.";
    }
    return "\nIMPORTANTE: Como é para 4-7 anos, equilibre atividades físicas/sensoriais simples com início de compreensão bíblica. Gere estação com ageBand '4-7' (e opcionalmente '8-11' para adaptação). A aplicação deve surgir somente depois da compreensão da Verdade Central e deve representar uma implicação legítima dela. Nunca transformar personagem bíblico em mero exemplo de 'seja como ele'. Use dinâmicas de movimento.";
  }

  Future<LessonPlan> generateLessonPlan(String theme, String ageGroup, String duration) async {
    // Para aula individual, pedimos série de 1 sem injetar semântica de série mensal
    final results = await generateMonthlySeries(theme, ageGroup, 1, isIndividual: true);
    if (results.isEmpty) {
      throw Exception('A IA não retornou uma aula válida.');
    }
    return results.first;
  }

  Future<List<LessonPlan>> generateMonthlySeries(
    String theme,
    String ageGroup,
    int count, {
    bool isIndividual = false,
    String? teacherId,
    String? teacherName,
  }) async {
    String apiKey = '';
    
    try {
      final doc = await FirebaseFirestore.instance.collection('config').doc('gemini').get();
      if (doc.exists && doc.data() != null) {
        final String key = doc.data()!['api_key'] ?? '';
        if (key != 'mock-key') {
          apiKey = key;
        }
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
    
    String countInstruction = isIndividual || count == 1
      ? 'Crie um plano de aula dinâmico e engajador para crianças.' 
      : 'Crie uma série progressiva e sequencial de $count aulas dinâmicas e engajadoras (numeradas claramente na ordem de Aula 1 até Aula $count, com progressão pedagógica clara entre cada aula da sequência).';

    final prompt = '''
Você é um especialista em ministério infantil cristão. 

HIERARQUIA OBRIGATÓRIA DA GERAÇÃO:
Seu processo de geração de cada plano de aula DEVE seguir estritamente esta ordem de prioridade lógica:
1. TEXTO BÍBLICO (leitura exata da passagem).
2. BIBLICAL CORE (exegese e estruturação hermenêutica).
3. VERDADE CENTRAL X (definição da verdade central teológica única).
4. ADAPTAÇÃO PEDAGÓGICA (ajuste de linguagem para as faixas oficiais '4-7' e '8-11').
5. CONTEÚDO DA AULA (criação dos cartões de estações, dinâmicas, orações, história e no mínimo 5 perguntas de quiz derivados de X).

Você NÃO deve partir primeiro de dinâmica, moral, comportamento desejado pelas crianças, jogo ou faixa etária. Primeiro deve compreender e estruturar a passagem bíblica.

PRINCÍPIO GOVERNANTE:
NÃO USE NENHUM EMOJI, ÍCONE OU SÍMBOLO ESPECIAL EM SUA RESPOSTA! A engine de renderização irá quebrar. Retorne APENAS texto simples.
Simplificar a linguagem, nunca substituir a mensagem do texto.
A 'centralTruth' é única para toda a aula. As faixas etárias nas estações ('stations') DEVEM usar apenas os códigos '4-7' e '8-11'.

PROTEÇÕES NARRATIVAS:
A história e os tópicos da história ('storyTopics') não podem inventar pensamentos dos personagens, emoções, diálogos ou detalhes de cenário que estejam ausentes do texto bíblico original. Mantenha fidelidade factual e textual estrita.

PROTEÇÕES CONTRA MORALISMO:
A aplicação prática nas estações, história ou atividades deve surgir somente depois da compreensão da Verdade Central e deve representar uma implicação legítima dela. Nunca transforme um personagem bíblico em um mero exemplo comportamental ('seja bom como fulano', 'faça como ciclano').

CONEXÃO CANÔNICA / CRISTOLÓGICA (SE HOUVER):
Não force conexões artificiais com Cristo em todas as aulas. Se houver uma conexão canônica legítima, apresente-a na estrutura:
TEXTO original -> DESENVOLVIMENTO CANÔNICO -> CONCLUSÃO em Cristo.

FREIO HERMENÊUTICO E REVISÃO INTERNA OBRIGATÓRIA:
Antes de produzir e devolver o JSON final, você DEVE revisar internamente todos os campos gerados ('objective', 'storyTopics', 'questions', 'stations', 'dynamicActivity', 'prayer') contra os limites de ('centralTruth', 'textSays', 'textAllowsToConclude', 'textDoesNotSay'). 
Se houver qualquer violação ou se alguma ideia vetada em 'textDoesNotSay' reaparecer em qualquer parte da aula, você DEVE corrigir e reescrever o conteúdo antes de retornar o JSON final.

$countInstruction
Tema${isIndividual ? '' : ' da Série'}: $theme
Faixa Etária: $ageGroup
$specialInstructions

RETORNE APENAS UM JSON VÁLIDO EXATAMENTE NESTE FORMATO (sem formatação markdown como ```json). Deve ser uma array de $count objetos na ordem exata da sequência (Aula 1 até Aula $count), e cada aula deve ter pelo menos 5 perguntas em "questions" onde o campo "answer" seja IDÊNTICO ao texto de uma das 4 "options":
[
  {
    "title": "Aula 1 - Título criativo da aula",
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
        "ageBand": "4-7",
        "duration": "15 min",
        "materials": ["item 1", "item 2"],
        "preparation": "como preparar o espaço para 4 a 7 anos",
        "executionSteps": ["passo 1", "passo 2"],
        "description": "descrição da estação para 4 a 7 anos"
      },
      {
        "ageBand": "8-11",
        "duration": "20 min",
        "materials": ["item 3"],
        "preparation": "como preparar para 8 a 11 anos",
        "executionSteps": ["passo 1", "passo 2"],
        "description": "descrição do desafio ou reflexão para 8 a 11 anos"
      }
    ],
    "questions": [
      {
        "question": "pergunta 1 sobre o texto bíblico",
        "options": ["Opção correta exata", "Opção incorreta 1", "Opção incorreta 2", "Opção incorreta 3"],
        "answer": "Opção correta exata",
        "curiosidade": "explicação curta do texto bíblico",
        "ageBand": "4-7"
      },
      {
        "question": "pergunta 2 sobre o texto bíblico",
        "options": ["Opção 1", "Opção 2 correta", "Opção 3", "Opção 4"],
        "answer": "Opção 2 correta",
        "curiosidade": "explicação curta do texto bíblico",
        "ageBand": "8-11"
      }
    ]
  }
]

PROIBIDO: Não utilize emojis em nenhum campo do JSON.
''';

    // Segurança: enviar a chave no cabeçalho x-goog-api-key em vez da query string (?key=...)
    // evita que o navegador registe a chave completa em URLs de erro no Console.
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent');
    
    http.Response? response;
    const int maxAttempts = 3;
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [{'text': prompt}]
              }
            ],
            'generationConfig': {
              'responseMimeType': 'application/json'
            }
          }),
        ).timeout(const Duration(seconds: 120));

        if ((response.statusCode == 503 || response.statusCode == 429) && attempt < maxAttempts) {
          final retryAfterHeader = response.headers['retry-after'];
          final retrySeconds = int.tryParse(retryAfterHeader ?? '') ?? (3 * attempt);
          await Future.delayed(Duration(seconds: retrySeconds.clamp(2, 15)));
          continue;
        }
        break;
      } on TimeoutException {
        throw Exception('A requisição para a IA excedeu o tempo limite de 120 segundos.');
      } catch (e) {
        if (attempt == maxAttempts) {
          throw Exception('Erro de conexão ao acessar a IA: ${_redact(e, apiKey)}');
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }

    if (response == null) {
      throw Exception('Não foi possível obter resposta da IA após várias tentativas.');
    }

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      
      final candidates = jsonResponse['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('A IA não retornou texto (Possível bloqueio de segurança).');
      }
      
      final content = candidates[0]?['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Formato de resposta inesperado (sem parts).');
      }
      
      final String? responseText = parts[0]?['text']?.toString();
      
      if (responseText != null) {
        String cleanJson = stripEmojis(responseText).trim();
        final firstBracket = cleanJson.indexOf(RegExp(r'[\{\[]'));
        final lastBracket = cleanJson.lastIndexOf(RegExp(r'[\}\]]'));
        if (firstBracket != -1 && lastBracket != -1 && lastBracket > firstBracket) {
          cleanJson = cleanJson.substring(firstBracket, lastBracket + 1);
        }
        
        dynamic decodedJson;
        try {
          decodedJson = jsonDecode(cleanJson);
        } catch (e) {
          throw Exception('A resposta da IA não é um JSON válido: $e');
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

        final List<dynamic> rawList = decodedJson;
        final List<Map<String, dynamic>> uniqueDataList = [];
        final Set<String> seenTitles = {};
        List<String> errors = [];

        for (int i = 0; i < rawList.length; i++) {
          final data = rawList[i];
          if (data == null || data is! Map) {
            errors.add('Índice $i: Formato do item corrompido (não é Map).');
            continue;
          }
          if (data['title'] == null ||
              data['keyVerse'] == null ||
              data['title'].toString().trim().isEmpty ||
              data['keyVerse'].toString().trim().isEmpty) {
            errors.add('Índice $i: Campos mínimos ausentes ou vazios (title ou keyVerse).');
            continue;
          }
          final cleanBaseTitle = stripEmojis(data['title'].toString().trim())
              .replaceFirst(RegExp(r'^aula\s*\d+\s*[-:]\s*', caseSensitive: false), '')
              .trim()
              .toLowerCase();
          if (seenTitles.contains(cleanBaseTitle)) {
            continue; // Ignora aula repetida gerada pela IA
          }
          seenTitles.add(cleanBaseTitle);
          uniqueDataList.add(Map<String, dynamic>.from(data));
          if (count > 0 && uniqueDataList.length >= count) {
            break; // Respeita o limite exato de aulas pedido pelo professor
          }
        }

        List<LessonPlan> validPlans = [];
        final int baseTimestamp = DateTime.now().millisecondsSinceEpoch;
        final String seriesId = 'series_$baseTimestamp';
        final String cleanTheme = stripEmojis(theme.trim());
        final int totalInSeries = uniqueDataList.length;

        for (int i = 0; i < uniqueDataList.length; i++) {
          final data = uniqueDataList[i];
          try {
            final int lessonNum = i + 1;
            String rawTitle = stripEmojis(data['title'].toString().trim())
                .replaceFirst(RegExp(r'^aula\s*\d+\s*[-:]\s*', caseSensitive: false), '')
                .trim();
            if (totalInSeries > 1) {
              rawTitle = 'Aula $lessonNum - $rawTitle';
            }

            validPlans.add(LessonPlan(
              id: baseTimestamp + (totalInSeries - i),
              title: rawTitle,
              ageGroup: ageGroup,
              objective: stripEmojis(data['objective']?.toString() ?? ''),
              keyVerse: stripEmojis(data['keyVerse'].toString().trim()),
              storyTopics: stripEmojis(data['storyTopics']?.toString() ?? ''),
              questions: stripEmojis(data['questions'] is List ? jsonEncode(data['questions']) : (data['questions']?.toString() ?? '')),
              dynamicActivity: stripEmojis(data['dynamicActivity']?.toString() ?? ''),
              prayer: stripEmojis(data['prayer']?.toString() ?? ''),
              ageProfile: ageProfile,
              supportsTeams: safeBool(data['supportsTeams'], fallback: false),
              stations: data['stations'] is List 
                  ? (data['stations'] as List).where((s) => s is Map).map((s) => MixedAgeStation.fromMap(Map<String, dynamic>.from(s as Map))).toList() 
                  : [],
              biblicalCore: (data['biblicalCore'] is Map) ? BiblicalCore.fromMap(Map<String, dynamic>.from(data['biblicalCore'] as Map)) : null,
              teacherId: teacherId,
              teacherName: teacherName,
              seriesId: seriesId,
              seriesTheme: cleanTheme,
              lessonNumber: lessonNum,
              totalLessonsInSeries: totalInSeries,
            ));
          } catch (e) {
            errors.add('Índice $i: Erro ao instanciar LessonPlan ($e).');
          }
        }

        if (validPlans.isEmpty) {
          throw Exception('Nenhum plano válido foi gerado. Erros encontrados: ${errors.join(" | ")}');
        }
        
        if (errors.isNotEmpty) {
          print('WARNING: Perda parcial de planos gerados. Erros: ${errors.join(" | ")}');
        }
        
        return validPlans;
      } else {
        throw Exception('A resposta da IA foi nula.');
      }
    } else {
      final detail = _extractApiErrorDetail(response.body, apiKey);
      if (response.statusCode == 503) {
        throw Exception('Serviço da IA temporariamente indisponível (HTTP 503) após $maxAttempts tentativas. Detalhe: $detail');
      } else if (response.statusCode == 429) {
        throw Exception('Limite de cota/requisições atingido na IA (HTTP 429). Detalhe: $detail');
      }
      throw Exception('Erro na API (Status ${response.statusCode}): $detail');
    }
  }
}
