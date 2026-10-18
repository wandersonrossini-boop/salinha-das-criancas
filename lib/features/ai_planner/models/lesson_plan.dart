import 'dart:convert';
import 'classroom_age_profile.dart';
import '../../../core/utils/safe_converters.dart';
import '../../../core/utils/emoji_stripper.dart';

class MixedAgeStation {
  final String ageBand;
  final String duration;
  final List<String> materials;
  final String preparation;
  final List<String> executionSteps;
  final String description;

  MixedAgeStation({
    required this.ageBand,
    required this.duration,
    required this.materials,
    required this.preparation,
    required this.executionSteps,
    required this.description,
  });

  /// Padroniza qualquer faixa etária para o padrão oficial: '4-7' ou '8-11'.
  static String normalizeAgeBand(String raw) {
    final clean = stripEmojis(raw).trim().toLowerCase();
    if (clean.contains('4-6') ||
        clean.contains('4–6') ||
        clean.contains('4 a 6') ||
        clean.contains('4-7') ||
        clean.contains('4–7') ||
        clean.contains('4 a 7') ||
        clean.contains('0-4')) {
      return '4-7';
    }
    if (clean.contains('7-8') ||
        clean.contains('9-11') ||
        clean.contains('7-11') ||
        clean.contains('7–11') ||
        clean.contains('7 a 11') ||
        clean.contains('8-11') ||
        clean.contains('8–11') ||
        clean.contains('8 a 11')) {
      return '8-11';
    }
    return clean.isEmpty ? '4-7' : raw.trim();
  }

  Map<String, dynamic> toMap() {
    return {
      'ageBand': normalizeAgeBand(ageBand),
      'duration': duration,
      'materials': materials,
      'preparation': preparation,
      'executionSteps': executionSteps,
      'description': description,
    };
  }

  factory MixedAgeStation.fromMap(Map<String, dynamic> map) {
    return MixedAgeStation(
      ageBand: normalizeAgeBand(map['ageBand']?.toString() ?? ''),
      duration: stripEmojis(map['duration']?.toString() ?? ''),
      materials: safeStringList(map['materials']).map((e) => stripEmojis(e)).toList(),
      preparation: stripEmojis(map['preparation']?.toString() ?? ''),
      executionSteps: safeStringList(map['executionSteps']).map((e) => stripEmojis(e)).toList(),
      description: stripEmojis(map['description']?.toString() ?? ''),
    );
  }
}

class BiblicalCore {
  final String passage;
  final String centralTruth;
  final List<String> textSays;
  final List<String> textAllowsToConclude;
  final List<String> textDoesNotSay;
  final List<String> historicalContext;
  final String theologicalCore;

  BiblicalCore({
    required this.passage,
    required this.centralTruth,
    required this.textSays,
    required this.textAllowsToConclude,
    required this.textDoesNotSay,
    required this.historicalContext,
    required this.theologicalCore,
  });

  Map<String, dynamic> toMap() {
    return {
      'passage': passage,
      'centralTruth': centralTruth,
      'textSays': textSays,
      'textAllowsToConclude': textAllowsToConclude,
      'textDoesNotSay': textDoesNotSay,
      'historicalContext': historicalContext,
      'theologicalCore': theologicalCore,
    };
  }

  factory BiblicalCore.fromMap(Map<String, dynamic> map) {
    return BiblicalCore(
      passage: stripEmojis(map['passage']?.toString() ?? ''),
      centralTruth: stripEmojis(map['centralTruth']?.toString() ?? ''),
      textSays: safeStringList(map['textSays']).map((e) => stripEmojis(e)).toList(),
      textAllowsToConclude: safeStringList(map['textAllowsToConclude']).map((e) => stripEmojis(e)).toList(),
      textDoesNotSay: safeStringList(map['textDoesNotSay']).map((e) => stripEmojis(e)).toList(),
      historicalContext: safeStringList(map['historicalContext']).map((e) => stripEmojis(e)).toList(),
      theologicalCore: stripEmojis(map['theologicalCore']?.toString() ?? ''),
    );
  }
}

class LessonPlan {
  final int? id;
  final String title;
  final String ageGroup;
  final String objective;
  final String keyVerse;
  final String storyTopics;
  final String questions;
  final String dynamicActivity;
  final String prayer;
  
  // Mixed Age extensions
  final ClassroomAgeProfile? ageProfile;
  final bool supportsTeams;
  final List<MixedAgeStation> stations;

  // Preparation extensions
  final BiblicalCore? biblicalCore;

  // Separação por Professor e Sequência de Série
  final String teacherId;
  final String teacherName;
  final String seriesId;
  final String seriesTheme;
  final int lessonNumber;
  final int totalLessonsInSeries;

  // Progresso e Conclusão da Aula
  final bool isCompleted;
  final int lastStepIndex;

  LessonPlan({
    this.id,
    required this.title,
    required this.ageGroup,
    required this.objective,
    required this.keyVerse,
    required this.storyTopics,
    required this.questions,
    required this.dynamicActivity,
    required this.prayer,
    this.ageProfile,
    this.supportsTeams = true,
    this.stations = const [],
    this.biblicalCore,
    String? teacherId,
    String? teacherName,
    String? seriesId,
    String? seriesTheme,
    int? lessonNumber,
    int? totalLessonsInSeries,
    bool? isCompleted,
    int? lastStepIndex,
  })  : teacherId = teacherId ?? '',
        teacherName = teacherName ?? '',
        seriesId = seriesId ?? '',
        seriesTheme = seriesTheme ?? '',
        lessonNumber = lessonNumber ?? 1,
        totalLessonsInSeries = totalLessonsInSeries ?? 1,
        isCompleted = isCompleted ?? false,
        lastStepIndex = lastStepIndex ?? 0;

  String get sequenceLabel {
    if (totalLessonsInSeries > 1) {
      return 'Aula $lessonNumber de $totalLessonsInSeries';
    }
    return 'Aula Individual';
  }

  LessonPlan copyWith({
    int? id,
    String? title,
    String? ageGroup,
    String? objective,
    String? keyVerse,
    String? storyTopics,
    String? questions,
    String? dynamicActivity,
    String? prayer,
    ClassroomAgeProfile? ageProfile,
    bool? supportsTeams,
    List<MixedAgeStation>? stations,
    BiblicalCore? biblicalCore,
    String? teacherId,
    String? teacherName,
    String? seriesId,
    String? seriesTheme,
    int? lessonNumber,
    int? totalLessonsInSeries,
    bool? isCompleted,
    int? lastStepIndex,
  }) {
    return LessonPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      ageGroup: ageGroup ?? this.ageGroup,
      objective: objective ?? this.objective,
      keyVerse: keyVerse ?? this.keyVerse,
      storyTopics: storyTopics ?? this.storyTopics,
      questions: questions ?? this.questions,
      dynamicActivity: dynamicActivity ?? this.dynamicActivity,
      prayer: prayer ?? this.prayer,
      ageProfile: ageProfile ?? this.ageProfile,
      supportsTeams: supportsTeams ?? this.supportsTeams,
      stations: stations ?? this.stations,
      biblicalCore: biblicalCore ?? this.biblicalCore,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      seriesId: seriesId ?? this.seriesId,
      seriesTheme: seriesTheme ?? this.seriesTheme,
      lessonNumber: lessonNumber ?? this.lessonNumber,
      totalLessonsInSeries: totalLessonsInSeries ?? this.totalLessonsInSeries,
      isCompleted: isCompleted ?? this.isCompleted,
      lastStepIndex: lastStepIndex ?? this.lastStepIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'ageGroup': ageGroup,
      'objective': objective,
      'keyVerse': keyVerse,
      'storyTopics': storyTopics,
      'questions': questions,
      'dynamicActivity': dynamicActivity,
      'prayer': prayer,
      'ageProfile': ageProfile?.toMap(),
      'supportsTeams': supportsTeams,
      'stations': stations.map((s) => s.toMap()).toList(),
      'biblicalCore': biblicalCore?.toMap(),
      'teacherId': teacherId,
      'teacherName': teacherName,
      'seriesId': seriesId,
      'seriesTheme': seriesTheme,
      'lessonNumber': lessonNumber,
      'totalLessonsInSeries': totalLessonsInSeries,
      'isCompleted': isCompleted,
      'lastStepIndex': lastStepIndex,
    };
  }

  factory LessonPlan.fromMap(Map<String, dynamic> map) {
    String questionsStr = '';
    if (map['questions'] is List) {
      questionsStr = stripEmojis(jsonEncode(map['questions']));
    } else {
      questionsStr = stripEmojis(map['questions']?.toString() ?? '');
    }

    // Deduplica estações que após normalização ficaram na mesma faixa ('4-7' ou '8-11')
    final List<MixedAgeStation> rawStations = map['stations'] is List
        ? (map['stations'] as List)
            .where((s) => s is Map)
            .map((s) => MixedAgeStation.fromMap(Map<String, dynamic>.from(s as Map)))
            .toList()
        : [];
    final Map<String, MixedAgeStation> uniqueStations = {};
    for (final st in rawStations) {
      uniqueStations.putIfAbsent(st.ageBand, () => st);
    }

    return LessonPlan(
      id: map['id'] != null ? safeInt(map['id'], fallback: 0) : null,
      title: stripEmojis(map['title']?.toString() ?? 'Aula Sem Título'),
      ageGroup: stripEmojis(map['ageGroup']?.toString() ?? '')
          .replaceAll('4-6', '4-7')
          .replaceAll('7-11', '8-11'),
      objective: stripEmojis(map['objective']?.toString() ?? ''),
      keyVerse: stripEmojis(map['keyVerse']?.toString() ?? ''),
      storyTopics: stripEmojis(map['storyTopics']?.toString() ?? ''),
      questions: questionsStr,
      dynamicActivity: stripEmojis(map['dynamicActivity']?.toString() ?? ''),
      prayer: stripEmojis(map['prayer']?.toString() ?? ''),
      ageProfile: (map['ageProfile'] is Map) ? ClassroomAgeProfile.fromMap(Map<String, dynamic>.from(map['ageProfile'] as Map)) : null,
      supportsTeams: safeBool(map['supportsTeams'], fallback: false),
      stations: uniqueStations.values.toList(),
      biblicalCore: (map['biblicalCore'] is Map) ? BiblicalCore.fromMap(Map<String, dynamic>.from(map['biblicalCore'] as Map)) : null,
      teacherId: map['teacherId']?.toString(),
      teacherName: map['teacherName'] != null ? stripEmojis(map['teacherName'].toString()) : null,
      seriesId: map['seriesId']?.toString(),
      seriesTheme: map['seriesTheme'] != null ? stripEmojis(map['seriesTheme'].toString()) : null,
      lessonNumber: map['lessonNumber'] != null ? safeInt(map['lessonNumber'], fallback: 1) : null,
      totalLessonsInSeries: map['totalLessonsInSeries'] != null ? safeInt(map['totalLessonsInSeries'], fallback: 1) : null,
      isCompleted: safeBool(map['isCompleted'], fallback: false),
      lastStepIndex: safeInt(map['lastStepIndex'], fallback: 0),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LessonPlan) return false;
    if (id != null && other.id != null) {
      return id == other.id;
    }
    return title == other.title && keyVerse == other.keyVerse && teacherId == other.teacherId && lessonNumber == other.lessonNumber;
  }

  @override
  int get hashCode {
    if (id != null) return id.hashCode;
    return Object.hash(title, keyVerse, teacherId, lessonNumber);
  }
}

