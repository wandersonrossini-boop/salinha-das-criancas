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
    };
  }

  factory LessonPlan.fromMap(Map<String, dynamic> map) {
    return LessonPlan(
      id: map['id'],
      title: map['title'],
      ageGroup: map['ageGroup'],
      objective: map['objective'],
      keyVerse: map['keyVerse'],
      storyTopics: map['storyTopics'],
      questions: map['questions'],
      dynamicActivity: map['dynamicActivity'],
      prayer: map['prayer'],
    );
  }
}
