import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/colors.dart';

class ChallengeResultScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const ChallengeResultScreen({super.key, required this.data});

  @override
  State<ChallengeResultScreen> createState() =>
      _ChallengeResultScreenState();
}

class _ChallengeResultScreenState
    extends State<ChallengeResultScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confetti;
  late AnimationController _scaleCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(
        duration: const Duration(seconds: 3));
    _scaleCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(
        parent: _scaleCtrl, curve: Curves.elasticOut);
    _scaleCtrl.forward();

    final correct = widget.data['correct'] as int? ?? 0;
    final total = widget.data['total'] as int? ?? 1;
    if (correct / total >= 0.7) {
      _confetti.play();
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final correct = widget.data['correct'] as int? ?? 0;
    final total = widget.data['total'] as int? ?? 1;
    final pct = total > 0 ? (correct / total * 100).round() : 0;
    final color = scoreColor(pct);
    final isWin = pct >= 70;

    return Scaffold(
      backgroundColor: kBgMain,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            colors: const [kOrange, kGreen, kYellow, kBlue, kPurple],
            numberOfParticles: 40,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  ScaleTransition(
                    scale: _scale,
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: 0.15),
                            border: Border.all(color: color, width: 4),
                          ),
                          child: Center(
                            child: Text(
                              '$pct%',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          isWin ? 'Tabriklaymiz!' : 'Yaxshi urinish!',
                          style: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isWin
                              ? 'Siz musobaqada g\'olib bo\'ldingiz!'
                              : 'Keyingi safar yaxshiroq natija ko\'rsatasiz',
                          style: const TextStyle(
                              color: kTextSecondary, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Stats row
                  Row(
                    children: [
                      _Stat(
                          label: "To'g'ri",
                          value: '$correct',
                          color: kGreen),
                      _Stat(
                          label: "Noto'g'ri",
                          value: '${total - correct}',
                          color: kRed),
                      _Stat(
                          label: 'Jami',
                          value: '$total',
                          color: kTextSecondary),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (isWin) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: kOrange.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt_rounded,
                              color: kOrange, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('XP qo\'shildi!',
                                    style: TextStyle(
                                        color: kOrange,
                                        fontWeight: FontWeight.w700)),
                                Text(
                                    'Musobaqa uchun bonus XP hisoblandi',
                                    style: TextStyle(
                                        color: kTextMuted,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.go('/student/dashboard'),
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('Asosiy sahifa'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/student/challenge'),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Yana urinish'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kTextSecondary,
                        side: const BorderSide(color: kBgBorder),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label,
                style:
                    const TextStyle(color: kTextMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
