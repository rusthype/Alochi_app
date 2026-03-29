import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/constants/colors.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 800;

    return Scaffold(
      backgroundColor: kBgMain,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _NavBar(isWide: isWide),
            _HeroSection(isWide: isWide),
            const _FeaturesSection(),
            const _StatsSection(),
            const _CtaSection(),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final bool isWide;
  const _NavBar({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: 16),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: kBgBorder))),
      child: Row(
        children: [
          const Icon(Icons.school_rounded, color: kOrange, size: 28),
          const SizedBox(width: 8),
          const Text("A'lochi",
              style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
          const Spacer(),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Kirish'),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final bool isWide;
  const _HeroSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: 80),
      child: isWide
          ? Row(children: [
              Expanded(child: _heroContent(context)),
              Expanded(child: _heroImage()),
            ])
          : Column(children: [
              _heroContent(context),
              const SizedBox(height: 40),
              _heroImage(),
            ]),
    );
  }

  Widget _heroContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: kOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kOrange.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, color: kOrange, size: 16),
              SizedBox(width: 4),
              Text("O'zbek ta'lim platformasi",
                  style: TextStyle(
                      color: kOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text("Bilimingizni\nsinang va\nrivojlaning",
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              height: 1.1,
            )),
        const SizedBox(height: 16),
        const Text(
          "Test ishlang, XP yig'ing, leaderboardda o'z o'rningizni egallab oling.",
          style: TextStyle(
              color: kTextSecondary, fontSize: 16, height: 1.6),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Boshlash'),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: kTextSecondary,
                side: const BorderSide(color: kBgBorder),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Batafsil'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _heroImage() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBgBorder),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_rounded, size: 80, color: kOrange),
            SizedBox(height: 16),
            Text("A'lochi",
                style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900)),
            Text('Gamified Education',
                style: TextStyle(color: kTextSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    const features = [
      (Icons.quiz_rounded, kOrange, 'Testlar',
          'Minglab test savollari bilan bilimingizni sinang'),
      (Icons.star_rounded, kYellow, 'XP & Darajalar',
          "Har bir test uchun tajriba ballari yig'ing"),
      (Icons.leaderboard_rounded, kGreen, 'Leaderboard',
          "Do'stlaringiz bilan raqobatlashing"),
      (Icons.storefront_rounded, kPurple, "Do'kon",
          "Tangalar bilan maxsus sovg'alar sotib oling"),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          const Text("Nima uchun A'lochi?",
              style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 40),
          LayoutBuilder(builder: (ctx, constraints) {
            final cols = constraints.maxWidth > 800 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: features
                  .map((f) => _FeatureCard(
                      icon: f.$1,
                      color: f.$2,
                      title: f.$3,
                      description: f.$4))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _FeatureCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBgBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 4),
          Expanded(
            child: Text(description,
                style: const TextStyle(
                    color: kTextSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    const stats = [
      ('10,000+', "O'quvchilar"),
      ('500+', 'Testlar'),
      ('50,000+', 'Savollar'),
      ('95%', 'Qoniqish'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      color: kBgCard,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats
            .map((s) => Column(
                  children: [
                    Text(s.$1,
                        style: const TextStyle(
                            color: kOrange,
                            fontSize: 32,
                            fontWeight: FontWeight.w900)),
                    Text(s.$2,
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 14)),
                  ],
                ))
            .toList(),
      ),
    );
  }
}

class _CtaSection extends StatelessWidget {
  const _CtaSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [kOrange.withValues(alpha: 0.2), kPurple.withValues(alpha: 0.2)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('Bugun boshlang!',
              style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Kirish'),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: kBgBorder))),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_rounded, color: kOrange, size: 20),
              SizedBox(width: 8),
              Text("A'lochi",
                  style: TextStyle(
                      color: kTextPrimary, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 8),
          Text("© 2026 A'lochi. Barcha huquqlar himoyalangan.",
              style: TextStyle(color: kTextMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
