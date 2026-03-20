import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:confetti/confetti.dart';
import '../../../shared/constants/colors.dart';
import '../../../core/models/test_model.dart';

class TestResultScreen extends StatefulWidget {
  final String id;
  final TestResultModel? result;

  const TestResultScreen({super.key, required this.id, this.result});

  @override
  State<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti =
        ConfettiController(duration: const Duration(seconds: 3));
    if (widget.result != null && widget.result!.score >= 80) {
      _confetti.play();
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    if (result == null) {
      return Scaffold(
        backgroundColor: kBgMain,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Natija topilmadi',
                  style: TextStyle(color: kTextSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    context.go('/student/dashboard'),
                child: const Text('Bosh sahifaga'),
              ),
            ],
          ),
        ),
      );
    }

    final color = scoreColor(result.score);

    return Scaffold(
      backgroundColor: kBgMain,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                SizedBox(
                  height: 200,
                  width: 200,
                  child: Stack(
                    children: [
                      PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: result.correct.toDouble(),
                              color: kGreen,
                              showTitle: false,
                              radius: 40,
                            ),
                            PieChartSectionData(
                              value: result.wrong.toDouble(),
                              color: kRed,
                              showTitle: false,
                              radius: 40,
                            ),
                            if (result.skipped > 0)
                              PieChartSectionData(
                                value: result.skipped.toDouble(),
                                color: kTextMuted,
                                showTitle: false,
                                radius: 40,
                              ),
                          ],
                          centerSpaceRadius: 60,
                          startDegreeOffset: -90,
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${result.score.toStringAsFixed(0)}%',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900),
                            ),
                            const Text('Ball',
                                style: TextStyle(
                                    color: kTextSecondary,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatBadge(
                        label: "To'g'ri",
                        value: '${result.correct}',
                        color: kGreen),
                    _StatBadge(
                        label: "Noto'g'ri",
                        value: '${result.wrong}',
                        color: kRed),
                    _StatBadge(
                        label: "O'tkazilgan",
                        value: '${result.skipped}',
                        color: kTextMuted),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RewardChip(
                        icon: Icons.bolt_rounded,
                        value: '+${result.xpEarned} XP',
                        color: kOrange),
                    const SizedBox(width: 12),
                    _RewardChip(
                        icon: Icons.monetization_on_rounded,
                        value: '+${result.coinsEarned}',
                        color: kYellow),
                  ],
                ),
                if (result.answers.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Javoblar sharhi',
                        style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 12),
                  ...result.answers.map((a) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kBgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: a.isCorrect
                                ? kGreen.withOpacity(0.3)
                                : kRed.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              a.isCorrect
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: a.isCorrect ? kGreen : kRed,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(a.questionText,
                                  style: const TextStyle(
                                      color: kTextPrimary,
                                      fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context
                            .go('/student/tests/${widget.id}/play'),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Qayta'),
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
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            context.go('/student/dashboard'),
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('Bosh sahifa'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                kOrange, kGreen, kYellow, kPurple, kBlue
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBadge(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w900)),
        Text(label,
            style: const TextStyle(
                color: kTextSecondary, fontSize: 12)),
      ],
    );
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _RewardChip(
      {required this.icon,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
