import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../core/api/student_api.dart';
import '../../../core/models/vocabulary.dart';

class QuizScreen extends StatefulWidget {
  final String topicId;
  const QuizScreen({super.key, required this.topicId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<VocabularyWord>? _words;
  List<List<VocabularyWord>>? _options;
  int _current = 0;
  String? _selected;
  bool _answered = false;
  int _correct = 0;
  bool _loading = true;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final words =
          await StudentApi().getVocabularyWords(widget.topicId);
      words.shuffle();
      final options = words.map((w) {
        final opts = [w];
        final others =
            words.where((o) => o.id != w.id).toList()..shuffle();
        opts.addAll(others.take(3));
        opts.shuffle();
        return opts;
      }).toList();
      setState(() {
        _words = words;
        _options = options;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _select(VocabularyWord opt, VocabularyWord correct) {
    if (_answered) return;
    setState(() {
      _selected = opt.id;
      _answered = true;
      if (opt.id == correct.id) _correct++;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_current < (_words?.length ?? 0) - 1) {
        setState(() {
          _current++;
          _selected = null;
          _answered = false;
        });
      } else {
        setState(() => _done = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          backgroundColor: kBgMain, body: LoadingOverlay());
    }

    final total = _words?.length ?? 0;

    if (_done || total == 0) {
      return Scaffold(
        backgroundColor: kBgMain,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 80, color: kGreen),
                const SizedBox(height: 16),
                const Text('Quiz yakunlandi!',
                    style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text("$_correct / $total to'g'ri",
                    style: TextStyle(
                        color: scoreColor(
                            total > 0 ? _correct * 100 / total : 0),
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () =>
                      context.go('/student/vocabulary'),
                  child: const Text("So'zlarga qaytish"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final word = _words![_current];
    final opts = _options![_current];

    return Scaffold(
      backgroundColor: kBgMain,
      appBar: AppBar(
          title: Text('${_current + 1} / $total')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_current + 1) / total,
                backgroundColor: kBgBorder,
                color: kOrange,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 32),
            const Text('Tarjimasini toping:',
                style: TextStyle(
                    color: kTextSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Text(word.word,
                style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 40),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2,
                children: opts.map((opt) {
                  final isSelected = _selected == opt.id;
                  final isCorrect = opt.id == word.id;
                  Color border = kBgBorder;
                  Color bg = kBgCard;
                  if (_answered) {
                    if (isCorrect) {
                      border = kGreen;
                      bg = kGreen.withOpacity(0.15);
                    } else if (isSelected) {
                      border = kRed;
                      bg = kRed.withOpacity(0.15);
                    }
                  } else if (isSelected) {
                    border = kOrange;
                    bg = kOrange.withOpacity(0.15);
                  }
                  return GestureDetector(
                    onTap: () => _select(opt, word),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: border, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          opt.translationRu.isNotEmpty
                              ? opt.translationRu
                              : opt.translationEn,
                          style: const TextStyle(
                              color: kTextPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
