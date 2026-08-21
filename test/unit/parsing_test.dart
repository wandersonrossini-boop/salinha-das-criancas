import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/utils/safe_converters.dart';
import '../../lib/features/ai_planner/models/lesson_plan.dart';
import '../../lib/features/ai_planner/models/classroom_age_profile.dart';

MixedAgeStation? findStationByAgeBand(List stations, String ageBand) {
  final matches = stations.where((item) => item.ageBand == ageBand).toList();
  if (matches.length > 1) {
    print('Aviso: Estação duplicada para a faixa $ageBand, utilizando a primeira ocorrência.');
  }
  return matches.firstOrNull;
}

void main() {
  group('Safe Converters - strict rules', () {
    test('safeBool', () {
      expect(safeBool(true), isTrue);
      expect(safeBool("true"), isTrue);
      expect(safeBool(1), isTrue);
      
      expect(safeBool(false), isFalse);
      expect(safeBool("false"), isFalse);
      expect(safeBool(0), isFalse);
      
      expect(safeBool("banana"), isFalse);
      expect(safeBool(null), isFalse);
      expect(safeBool(2), isFalse);
      expect(safeBool(-1), isFalse);
      expect(safeBool({}), isFalse);
      expect(safeBool([]), isFalse);
    });

    test('safeInt', () {
      expect(safeInt(15, fallback: 0), 15);
      expect(safeInt("15", fallback: 0), 15);
      expect(safeInt(15.5, fallback: 0), 15); // double
      expect(safeInt("banana", fallback: 10), 10);
      expect(safeInt(null, fallback: 10), 10);
      expect(safeInt({}, fallback: 10), 10);
      expect(safeInt([], fallback: 10), 10);
      
      expect(safeInt(5, fallback: 10, min: 10), 10);
      expect(safeInt(20, fallback: 10, max: 15), 15);
    });

    test('safeStringList', () {
      expect(safeStringList(["a", "b"]), ["a", "b"]);
      expect(safeStringList(["a", null, "b", "  "]), ["a", "b"]);
      expect(safeStringList("banana"), []);
      expect(safeStringList(15), []);
      expect(safeStringList({"a": "b"}), []);
      expect(safeStringList(null), []);
    });
  });

  group('Parsing Raiz e Seleção por AgeBand', () {
    test('Root Map fallback and required fields', () {
      final jsonObject = {
        'title': 'Aula 1',
        'keyVerse': 'João 3:16',
        'supportsTeams': "banana", // Invalid bool -> false
        'stations': [
          {
            'ageBand': '4-6',
            'duration': '15',
            'materials': ['papel', null],
            'preparation': 'Cortar papel',
            'executionSteps': ['Passo 1'],
            'description': 'Fazer barco'
          },
          {
            'ageBand': '4-6', // Duplicate
            'duration': 20,
            'materials': [],
            'preparation': '',
            'executionSteps': [],
            'description': 'Duplicate'
          },
          {
            'ageBand': '9-11', // Faltando 7-8 e fora de ordem logicamente
            'duration': 20,
            'materials': 'banana', // Inválido -> []
            'preparation': '',
            'executionSteps': [],
            'description': 'Debate'
          }
        ]
      };
      
      final plan = LessonPlan.fromMap(jsonObject);
      expect(plan.title, 'Aula 1');
      expect(plan.keyVerse, 'João 3:16');
      expect(plan.supportsTeams, isFalse);
      
      // Simular findStationByAgeBand
      final station4_6 = findStationByAgeBand(plan.stations, '4-6');
      expect(station4_6, isNotNull);
      expect(station4_6!.description, 'Fazer barco'); // Gets the first one deterministically
      
      final station7_8 = findStationByAgeBand(plan.stations, '7-8');
      expect(station7_8, isNull);
    });
  });
}
