import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../core/api/student_api.dart';
import '../../../core/models/test_model.dart';

class TestPlayScreen extends StatefulWidget {
  final String id;
  const TestPlayScreen({super.key, required this.id});

  @override
  State<TestPlayScreen> createState() => _TestPlayScreenState();
}

class _TestPlayScreenState extends State<TestPlayScreen> {
  List<QuestionModel> _questions = [];
  // Maps questionId -> selected option index (0-based)
  final Map<String, int> _answers = {};
  int _current = 0;
  bool _loading = true;
  bool _submitting = false;
  int _secondsLeft = 1800; // Total time
  int _questionSecondsLeft = 30; // Per-question timer
  Timer? _timer;
  Timer? _questionTimer;
  String? _error;
  bool _showFeedback = false;

  @override
  void initState() {
    super.initState();
    _loadTest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _questionTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTest() async {
    try {
      final data = await StudentApi().getTestDetail(widget.id);
      final questions = (data['questions'] as List? ?? [])
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList();
      final minutes = data['time_limit_minutes'] as int? ?? 30;
      setState(() {
        _questions = questions;
        _secondsLeft = minutes * 60;
        _loading = false;
      });
      _startTimer();
      _startQuestionTimer();
    } catch (e) {
      setState(() {
        _error = 'Test yuklanmadi: $e';
        _loading = false;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        _submit();
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    _questionSecondsLeft = 30;
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_questionSecondsLeft <= 0) {
        _questionTimer?.cancel();
        _next();
      } else {
        if (mounted) setState(() => _questionSecondsLeft--);
      }
    });
  }

  void _next() {
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _showFeedback = false;
      });
      _startQuestionTimer();
    } else if (_current == _questions.length - 1) {
      _showSubmitDialog();
    }
  }

  void _prev() {
    if (_current > 0) {
      setState(() {
        _current--;
        _showFeedback = false;
      });
      _startQuestionTimer();
    }
  }

  void _onOptionSelected(int idx) {
    if (_showFeedback) return;
    setState(() {
      _answers[_questions[_current].id] = idx;
      _showFeedback = true;
    });

    // Pause timers during feedback
    _questionTimer?.cancel();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _next();
    });
  }

  Future<void> _showSubmitDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBgCard,
        title: const Text('Testni yakunlash?',
            style: TextStyle(color: kTextPrimary)),
        content: Text('Javob berilgan: ${_answers.length}/${_questions.length}',
            style: const TextStyle(color: kTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor', style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yuborish'),
          ),
        ],
      ),
    );
    if (confirmed == true) _submit();
  }

  Future<void> _submit() async {
    _timer?.cancel();
    _questionTimer?.cancel();
    setState(() => _submitting = true);
    try {
      final result = await StudentApi().submitTest(widget.id, _answers);
      if (mounted) {
        context.go('/student/tests/${widget.id}/result', extra: result);
      }
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = 'Yuborishda xatolik: $e';
      });
    }
  }

  String get _timerText {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_secondsLeft < 60) return kRed;
    if (_secondsLeft < 300) return kYellow;
    return kOrange;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: kBgMain, body: LoadingOverlay());
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: kBgMain,
        body: Center(child: Text(_error!, style: const TextStyle(color: kRed))),
      );
    }

    final q = _questions[_current];
    final progress = (_current + 1) / _questions.length;

    return Scaffold(
      backgroundColor: kBgMain,
      appBar: AppBar(
        title: Text('${_current + 1} / ${_questions.length}'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _timerColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: kOrange),
                const SizedBox(width: 4),
                Text(_timerText,
                    style: TextStyle(
                        color: _timerColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Stack(
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: kBgBorder,
                color: kOrange,
                minHeight: 4,
              ),
              LinearProgressIndicator(
                value: _questionSecondsLeft / 30,
                backgroundColor: Colors.transparent,
                color: kGreen.withValues(alpha: 0.5),
                minHeight: 4,
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Savol",
                          style: TextStyle(color: kTextMuted, fontSize: 12)),
                      Text("$_questionSecondsLeft s",
                          style: TextStyle(
                              color: _questionSecondsLeft < 10 ? kRed : kGreen,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (q.image != null)
                    Container(
                      height: 180,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(q.image!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  Text(q.text,
                      style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 24),
                  ...q.options.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final opt = entry.value;
                    final isSelected = _answers[q.id] == idx;
                    
                    Color itemColor = isSelected ? kOrange : kBgBorder;
                    if (_showFeedback && isSelected) {
                      itemColor = kGreen; // For prototype we show green on selection
                    }

                    return GestureDetector(
                      onTap: () => _onOptionSelected(idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? itemColor.withValues(alpha: 0.1)
                              : kBgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? itemColor : kBgBorder,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected ? itemColor : kBgBorder,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(opt.label,
                                    style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : kTextSecondary,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(opt.text,
                                  style: TextStyle(
                                      color: isSelected
                                          ? kTextPrimary
                                          : kTextSecondary,
                                      fontSize: 15)),
                            ),
                            if (_showFeedback && isSelected)
                              const Icon(Icons.check_circle_rounded, color: kGreen),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: kBgCard,
              border: Border(top: BorderSide(color: kBgBorder)),
            ),
            child: Row(
              children: [
                if (_current > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _prev,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Oldingi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kTextSecondary,
                        side: const BorderSide(color: kBgBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                if (_current > 0) const SizedBox(width: 12),
                Expanded(
                  child: _current < _questions.length - 1
                      ? ElevatedButton.icon(
                          onPressed: _next,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Keyingi'),
                        )
                      : ElevatedButton.icon(
                          onPressed: _submitting ? null : _showSubmitDialog,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Yuborish'),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
