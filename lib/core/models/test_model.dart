class TestModel {
  final String id;
  final String title;
  final int questionCount;
  final int timeLimitMinutes;
  final String? bookTitle;
  final String? difficulty;
  final String? coverImage;

  const TestModel({
    required this.id,
    required this.title,
    required this.questionCount,
    required this.timeLimitMinutes,
    this.bookTitle,
    this.difficulty,
    this.coverImage,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      questionCount: json['question_count'] ?? 0,
      timeLimitMinutes: json['time_limit_minutes'] ?? 30,
      bookTitle: json['book']?['title'] ?? json['book_title'],
      difficulty: json['difficulty'],
      coverImage: json['cover_image'],
    );
  }
}

class QuestionModel {
  final String id;
  final String text;
  final String? image;
  final List<OptionModel> options;

  const QuestionModel({
    required this.id,
    required this.text,
    this.image,
    required this.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id']?.toString() ?? '',
      text: json['text'] ?? '',
      image: json['image'],
      options: (json['options'] as List? ?? [])
          .map((o) => OptionModel.fromJson(o))
          .toList(),
    );
  }
}

class OptionModel {
  final String id;
  final String label;
  final String text;

  const OptionModel({required this.id, required this.label, required this.text});

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    return OptionModel(
      id: json['id']?.toString() ?? '',
      label: json['label'] ?? '',
      text: json['text'] ?? '',
    );
  }
}

class TestResultModel {
  final String attemptId;
  final double score;
  final int correct;
  final int wrong;
  final int skipped;
  final int xpEarned;
  final int coinsEarned;
  final List<AnswerReviewModel> answers;

  const TestResultModel({
    required this.attemptId,
    required this.score,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.xpEarned,
    required this.coinsEarned,
    required this.answers,
  });

  factory TestResultModel.fromJson(Map<String, dynamic> json) {
    return TestResultModel(
      attemptId:
          json['attempt_id']?.toString() ?? json['id']?.toString() ?? '',
      score: (json['score_percent'] as num?)?.toDouble() ??
          (json['score'] as num?)?.toDouble() ??
          0.0,
      correct: json['correct_count'] ?? json['correct'] ?? 0,
      wrong: json['incorrect_count'] ??
          json['wrong_count'] ??
          json['wrong'] ??
          0,
      skipped: json['skipped_count'] ?? json['skipped'] ?? 0,
      xpEarned: json['xp_earned'] ?? json['xp_reward'] ?? 0,
      coinsEarned: json['coins_earned'] ?? 0,
      answers: (json['answers'] as List? ?? [])
          .map((a) => AnswerReviewModel.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AnswerReviewModel {
  final String questionText;
  final String selectedLabel;
  final String correctLabel;
  final bool isCorrect;

  const AnswerReviewModel({
    required this.questionText,
    required this.selectedLabel,
    required this.correctLabel,
    required this.isCorrect,
  });

  factory AnswerReviewModel.fromJson(Map<String, dynamic> json) {
    return AnswerReviewModel(
      questionText: json['question_text'] ?? '',
      selectedLabel: json['selected_label'] ?? '-',
      correctLabel: json['correct_label'] ?? '',
      isCorrect: json['is_correct'] ?? false,
    );
  }
}
