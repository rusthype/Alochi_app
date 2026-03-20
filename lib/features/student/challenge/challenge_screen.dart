import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../core/api/student_api.dart';

final _challengeProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final list = await StudentApi().getChallenges();
  // Return first available/active challenge, or empty map
  if (list.isEmpty) return <String, dynamic>{};
  return list.first;
});

class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({super.key});

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen>
    with TickerProviderStateMixin {
  int _currentQuestion = 0;
  int? _selected;
  bool _answered = false;
  final List<Map<String, dynamic>> _answers = [];
  late AnimationController _feedbackCtrl;
  late Animation<Color?> _bgAnim;

  @override
  void initState() {
    super.initState();
    _feedbackCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _bgAnim = ColorTween(begin: Colors.transparent, end: Colors.transparent)
        .animate(_feedbackCtrl);
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  void _onSelect(
      int idx, List<Map<String, dynamic>> questions, bool isCorrect) {
    if (_answered) return;
    setState(() {
      _selected = idx;
      _answered = true;
    });
    _answers.add({
      'question_index': _currentQuestion,
      'selected': idx,
      'correct': isCorrect,
    });
    _bgAnim = ColorTween(
      begin: isCorrect ? kGreen.withOpacity(0.1) : kRed.withOpacity(0.1),
      end: Colors.transparent,
    ).animate(_feedbackCtrl);
    _feedbackCtrl.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        if (_currentQuestion < questions.length - 1) {
          setState(() {
            _currentQuestion++;
            _selected = null;
            _answered = false;
          });
        } else {
          _finish(questions);
        }
      });
    });
  }

  void _finish(List<Map<String, dynamic>> questions) {
    final correct = _answers.where((a) => a['correct'] == true).length;
    context.go('/student/challenge/result', extra: {
      'correct': correct,
      'total': questions.length,
      'answers': _answers,
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_challengeProvider);
    return async.when(
      loading: () => const Scaffold(
          backgroundColor: kBgMain, body: LoadingWidget()),
      error: (e, _) => Scaffold(
        backgroundColor: kBgMain,
        appBar: AppBar(title: const Text('Kunlik musobaqa')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: kRed, size: 48),
              const SizedBox(height: 16),
              Text('Musobaqa topilmadi', style: const TextStyle(color: kTextSecondary)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => context.go('/student/dashboard'),
                child: const Text('Orqaga'),
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        final questions = ((data['questions'] ?? []) as List)
            .cast<Map<String, dynamic>>();
        if (questions.isEmpty) {
          return Scaffold(
            backgroundColor: kBgMain,
            appBar: AppBar(title: const Text('Kunlik musobaqa')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: kGreen, size: 64),
                  const SizedBox(height: 16),
                  const Text("Bugungi musobaqa yakunlandi!",
                      style: TextStyle(color: kTextPrimary, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text("Ertaga qaytib keling",
                      style: TextStyle(color: kTextSecondary)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/student/dashboard'),
                    child: const Text('Asosiy sahifa'),
                  ),
                ],
              ),
            ),
          );
        }
        final q = questions[_currentQuestion];
        final options = ((q['options'] ?? []) as List)
            .cast<Map<String, dynamic>>();
        final correctIdx = q['correct_index'] as int? ?? 0;
        final totalTime = data['time_limit'] as int? ?? 300;
        final opponent = data['opponent'] as Map<String, dynamic>?;

        return AnimatedBuilder(
          animation: _bgAnim,
          builder: (ctx, child) => Scaffold(
            backgroundColor: _bgAnim.value == Colors.transparent
                ? kBgMain
                : _bgAnim.value ?? kBgMain,
            appBar: AppBar(
              title: const Text('Kunlik musobaqa'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: child,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header: opponent + timer
                if (opponent != null) ...[
                  _OpponentCard(opponent: opponent, timeLimit: totalTime),
                  const SizedBox(height: 16),
                ],
                // Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_currentQuestion + 1} / ${questions.length}',
                      style: const TextStyle(
                          color: kTextSecondary, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${_answers.where((a) => a['correct'] == true).length} to\'g\'ri',
                      style: const TextStyle(color: kGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentQuestion + 1) / questions.length,
                    backgroundColor: kBgBorder,
                    color: kOrange,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 24),
                // Question
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kBgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBgBorder),
                  ),
                  child: Text(
                    q['question'] as String? ?? q['text'] as String? ?? '',
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                // Options
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.2,
                    children: List.generate(options.length, (i) {
                      final opt = options[i];
                      final label = ['A', 'B', 'C', 'D'][i];
                      Color borderColor = kBgBorder;
                      Color bgColor = kBgCard;
                      if (_answered) {
                        if (i == correctIdx) {
                          borderColor = kGreen;
                          bgColor = kGreen.withOpacity(0.15);
                        } else if (i == _selected) {
                          borderColor = kRed;
                          bgColor = kRed.withOpacity(0.15);
                        }
                      } else if (_selected == i) {
                        borderColor = kOrange;
                        bgColor = kOrange.withOpacity(0.15);
                      }
                      return GestureDetector(
                        onTap: () => _onSelect(
                            i, questions, i == correctIdx),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: borderColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(label,
                                      style: TextStyle(
                                          color: borderColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  opt['text'] as String? ?? '',
                                  style: const TextStyle(
                                      color: kTextPrimary, fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OpponentCard extends StatefulWidget {
  final Map<String, dynamic> opponent;
  final int timeLimit;
  const _OpponentCard(
      {required this.opponent, required this.timeLimit});

  @override
  State<_OpponentCard> createState() => _OpponentCardState();
}

class _OpponentCardState extends State<_OpponentCard> {
  late int _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.timeLimit;
    _tick();
  }

  void _tick() {
    if (!mounted) return;
    if (_remaining <= 0) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _remaining--);
        _tick();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining ~/ 60;
    final seconds = _remaining % 60;
    final timeStr =
        '$minutes:${seconds.toString().padLeft(2, '0')}';
    final color = _remaining < 60
        ? kRed
        : _remaining < 120
            ? kYellow
            : kGreen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOrange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: kPurple.withOpacity(0.2),
                shape: BoxShape.circle),
            child: const Center(
              child: Icon(Icons.person_rounded,
                  color: kPurple, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    widget.opponent['name'] as String? ??
                        'Raqib',
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w600)),
                Text(
                    '${widget.opponent['xp'] ?? 0} XP',
                    style:
                        const TextStyle(color: kTextMuted, fontSize: 12)),
              ],
            ),
          ),
          Column(
            children: [
              Icon(Icons.timer_rounded, color: color, size: 20),
              Text(timeStr,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }
}
