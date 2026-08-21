import 'dart:convert';
import 'classroom_age_profile.dart';
import '../../../core/utils/safe_converters.dart';

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

  Map<String, dynamic> toMap() {
    return {
      'ageBand': ageBand,
      'duration': duration,
      'materials': materials,
      'preparation': preparation,
      'executionSteps': executionSteps,
      'description': description,
    };
  }

  factory MixedAgeStation.fromMap(Map<String, dynamic> map) {
    return MixedAgeStation(
      ageBand: map['ageBand']?.toString() ?? '',
      duration: map['duration']?.toString() ?? '',
      materials: safeStringList(map['materials']),
      preparation: map['preparation']?.toString() ?? '',
      executionSteps: safeStringList(map['executionSteps']),
      description: map['description']?.toString() ?? '',
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
      passage: map['passage']?.toString() ?? '',
      centralTruth: map['centralTruth']?.toString() ?? '',
      textSays: safeStringList(map['textSays']),
      textAllowsToConclude: safeStringList(map['textAllowsToConclude']),
      textDoesNotSay: safeStringList(map['textDoesNotSay']),
      historicalContext: safeStringList(map['historicalContext']),
      theologicalCore: map['theologicalCore']?.toString() ?? '',
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
  });

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
    };
  }

  factory LessonPlan.fromMap(Map<String, dynamic> map) {
    return LessonPlan(
      id: map['id'],
      title: map['title']?.toString() ?? 'Aula Sem Título',
      ageGroup: map['ageGroup']?.toString() ?? '',
      objective: map['objective']?.toString() ?? '',
      keyVerse: map['keyVerse']?.toString() ?? '',
      storyTopics: map['storyTopics']?.toString() ?? '',
      questions: map['questions']?.toString() ?? '',
      dynamicActivity: map['dynamicActivity']?.toString() ?? '',
      prayer: map['prayer']?.toString() ?? '',
      ageProfile: map['ageProfile'] != null ? ClassroomAgeProfile.fromMap(map['ageProfile']) : null,
      supportsTeams: safeBool(map['supportsTeams'], fallback: false),
      stations: map['stations'] is List 
          ? (map['stations'] as List).map((s) => MixedAgeStation.fromMap(s)).toList() 
          : [],
      biblicalCore: (map['biblicalCore'] is Map) ? BiblicalCore.fromMap(Map<String, dynamic>.from(map['biblicalCore'] as Map)) : null,
    );
  }
}
