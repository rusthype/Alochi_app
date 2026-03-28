import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../core/api/student_api.dart';
import '../../../core/models/vocabulary.dart';

final _wordsProvider =
    FutureProvider.family<List<VocabularyWord>, String>(
        (ref, topicId) async {
  return StudentApi().getVocabularyWords(topicId);
});

class FlashcardScreen extends ConsumerStatefulWidget {
  final String topicId;
  const FlashcardScreen({super.key, required this.topicId});

  @override
  ConsumerState<FlashcardScreen> createState() =>
      _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  bool _showBack = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _anim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_showBack) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  void _go(int delta, int total) {
    final next = _current + delta;
    if (next >= 0 && next < total) {
      setState(() {
        _current = next;
        _showBack = false;
      });
      _ctrl.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_wordsProvider(widget.topicId));
    return Scaffold(
      backgroundColor: kBgMain,
      appBar: AppBar(title: const Text('Flashcard')),
      body: async.when(
        loading: () => const LoadingOverlay(),
        error: (e, _) => Center(
            child: Text('Xatolik: $e',
                style: const TextStyle(color: kRed))),
        data: (words) {
          if (words.isEmpty) {
            return const Center(
              child: Text("So'zlar topilmadi",
                  style: TextStyle(color: kTextSecondary)),
            );
          }
          final word = words[_current];
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('${_current + 1} / ${words.length}',
                    style: const TextStyle(color: kTextSecondary)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_current + 1) / words.length,
                    backgroundColor: kBgBorder,
                    color: kOrange,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: GestureDetector(
                    onTap: _flip,
                    child: AnimatedBuilder(
                      animation: _anim,
                      builder: (ctx, _) {
                        final angle = _anim.value * 3.14159;
                        final showFront = angle < 1.5708;
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(angle),
                          child: showFront
                              ? _CardFace(
                                  color: kBgCard,
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Text("O'zbekcha",
                                          style: TextStyle(
                                              color: kTextMuted,
                                              fontSize: 12)),
                                      const SizedBox(height: 16),
                                      Text(word.word,
                                          style: const TextStyle(
                                              color: kTextPrimary,
                                              fontSize: 32,
                                              fontWeight:
                                                  FontWeight.w900),
                                          textAlign: TextAlign.center),
                                      const SizedBox(height: 24),
                                      const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.touch_app_rounded,
                                              color: kTextMuted,
                                              size: 16),
                                          Text('  Bosing',
                                              style: TextStyle(
                                                  color: kTextMuted,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..rotateY(3.14159),
                                  child: _CardFace(
                                    color: kOrange.withValues(alpha: 0.1),
                                    borderColor:
                                        kOrange.withValues(alpha: 0.4),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (word.translationRu
                                            .isNotEmpty) ...[
                                          const Text('RU',
                                              style: TextStyle(
                                                  color: kTextMuted,
                                                  fontSize: 11)),
                                          Text(word.translationRu,
                                              style: const TextStyle(
                                                  color: kTextPrimary,
                                                  fontSize: 24,
                                                  fontWeight:
                                                      FontWeight.w700),
                                              textAlign:
                                                  TextAlign.center),
                                          const SizedBox(height: 12),
                                        ],
                                        if (word.translationEn
                                            .isNotEmpty) ...[
                                          const Text('EN',
                                              style: TextStyle(
                                                  color: kTextMuted,
                                                  fontSize: 11)),
                                          Text(word.translationEn,
                                              style: const TextStyle(
                                                  color: kTextSecondary,
                                                  fontSize: 20),
                                              textAlign:
                                                  TextAlign.center),
                                          const SizedBox(height: 12),
                                        ],
                                        if (word.exampleSentence !=
                                            null) ...[
                                          const Divider(
                                              color: kBgBorder),
                                          Text(word.exampleSentence!,
                                              style: const TextStyle(
                                                  color: kTextMuted,
                                                  fontSize: 13,
                                                  fontStyle:
                                                      FontStyle.italic),
                                              textAlign:
                                                  TextAlign.center),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _current > 0
                            ? () => _go(-1, words.length)
                            : null,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Oldingi'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kTextSecondary,
                          side: const BorderSide(color: kBgBorder),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _current < words.length - 1
                          ? ElevatedButton.icon(
                              onPressed: () =>
                                  _go(1, words.length),
                              icon: const Icon(
                                  Icons.arrow_forward_rounded),
                              label: const Text('Keyingi'),
                            )
                          : ElevatedButton.icon(
                              onPressed: () => context.go(
                                  '/student/vocabulary/${widget.topicId}/quiz'),
                              icon: const Icon(Icons.quiz_rounded),
                              label: const Text('Quiz'),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color? borderColor;
  const _CardFace(
      {required this.child, required this.color, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: borderColor ?? kBgBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }
}
