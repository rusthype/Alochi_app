import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../core/api/student_api.dart';
import '../../../core/models/vocabulary.dart';

final _vocabTopicsProvider = FutureProvider<List<VocabularyTopic>>((ref) async {
  return StudentApi().getVocabularyTopics();
});

class VocabularyScreen extends ConsumerWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_vocabTopicsProvider);
    return Scaffold(
      backgroundColor: kBgMain,
      appBar: AppBar(title: const Text("So'zlar")),
      body: async.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(
            child: Text('Xatolik: $e', style: const TextStyle(color: kRed))),
        data: (topics) {
          if (topics.isEmpty) {
            return const AlochiEmptyState(title: "So'z mavzulari topilmadi");
          }
          return LayoutBuilder(builder: (ctx, constraints) {
            final cols = constraints.maxWidth > 600 ? 3 : 2;
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                childAspectRatio: 0.95,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: topics.length,
              itemBuilder: (ctx, i) => _TopicCard(topic: topics[i]),
            );
          });
        },
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final VocabularyTopic topic;
  const _TopicCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBgBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(topic.title,
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text("${topic.wordCount} so'z",
                    style: const TextStyle(color: kTextMuted, fontSize: 12)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: topic.progress,
                    backgroundColor: kBgBorder,
                    color: kGreen,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 2),
                Text('${(topic.progress * 100).toInt()}%',
                    style: const TextStyle(color: kTextMuted, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      context.go('/student/vocabulary/${topic.id}/flashcard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kBlue,
                    side: BorderSide(color: kBlue.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  child: const Text('Flashcard'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      context.go('/student/vocabulary/${topic.id}/quiz'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  child: const Text('Quiz'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
