class VocabularyTopic {
  final String id;
  final String title;
  final int wordCount;
  final int learnedCount;

  const VocabularyTopic({
    required this.id,
    required this.title,
    required this.wordCount,
    required this.learnedCount,
  });

  double get progress => wordCount > 0 ? learnedCount / wordCount : 0.0;

  factory VocabularyTopic.fromJson(Map<String, dynamic> json) {
    return VocabularyTopic(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      wordCount: json['word_count'] ?? 0,
      learnedCount: json['learned_count'] ?? 0,
    );
  }
}

class VocabularyWord {
  final String id;
  final String word;
  final String translationRu;
  final String translationEn;
  final String? exampleSentence;

  const VocabularyWord({
    required this.id,
    required this.word,
    required this.translationRu,
    required this.translationEn,
    this.exampleSentence,
  });

  factory VocabularyWord.fromJson(Map<String, dynamic> json) {
    return VocabularyWord(
      id: json['id']?.toString() ?? '',
      word: json['word'] ?? '',
      translationRu: json['translation_ru'] ?? json['translation'] ?? '',
      translationEn: json['translation_en'] ?? '',
      exampleSentence: json['example_sentence'],
    );
  }
}
