import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/api/student_api.dart';
import '../../../core/models/test_model.dart';

final _booksProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return StudentApi().getBooks();
});

final _selectedBookProvider = StateProvider<String?>((ref) => null);
final _searchProvider = StateProvider<String>((ref) => '');

final _testListProvider = FutureProvider<List<TestModel>>((ref) async {
  final book = ref.watch(_selectedBookProvider);
  final search = ref.watch(_searchProvider);
  return StudentApi().getTestCatalog(bookId: book, search: search);
});

class TestListScreen extends ConsumerWidget {
  const TestListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(_booksProvider);
    final testsAsync = ref.watch(_testListProvider);
    final selectedBook = ref.watch(_selectedBookProvider);

    return Scaffold(
      backgroundColor: kBgMain,
      appBar: AppBar(title: const Text('Testlar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Test qidirish...',
                prefixIcon:
                    const Icon(Icons.search_rounded),
                suffixIcon: ref.watch(_searchProvider).isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () =>
                            ref.read(_searchProvider.notifier).state = '',
                      )
                    : null,
              ),
              onChanged: (v) =>
                  ref.read(_searchProvider.notifier).state = v,
            ),
          ),
          booksAsync.when(
            loading: () => const SizedBox(height: 56),
            error: (_, __) => const SizedBox.shrink(),
            data: (books) => SizedBox(
              height: 56,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                itemCount: books.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Barchasi'),
                        selected: selectedBook == null,
                        onSelected: (_) => ref
                            .read(_selectedBookProvider.notifier)
                            .state = null,
                        selectedColor: kOrange,
                      ),
                    );
                  }
                  final book = books[i - 1];
                  final id = book['id']?.toString();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(book['title'] as String? ?? ''),
                      selected: selectedBook == id,
                      onSelected: (_) => ref
                          .read(_selectedBookProvider.notifier)
                          .state = id,
                      selectedColor: kOrange,
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: testsAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(
                  child: Text('Xatolik: $e',
                      style: const TextStyle(color: kRed))),
              data: (tests) {
                if (tests.isEmpty) {
                  return const EmptyState(
                      message: 'Testlar topilmadi',
                      icon: Icons.quiz_outlined);
                }
                return LayoutBuilder(builder: (ctx, constraints) {
                  final cols = constraints.maxWidth > 900
                      ? 4
                      : constraints.maxWidth > 600
                          ? 3
                          : 2;
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      childAspectRatio: 0.85,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: tests.length,
                    itemBuilder: (ctx, i) =>
                        _TestCard(test: tests[i]),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  final TestModel test;
  const _TestCard({required this.test});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBgBorder),
      ),
      child: InkWell(
        onTap: () => context.go('/student/tests/${test.id}/play'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (test.bookTitle != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(test.bookTitle!,
                      style: const TextStyle(
                          color: kBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(test.title,
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.quiz_rounded,
                      size: 12, color: kTextMuted),
                  const SizedBox(width: 4),
                  Text('${test.questionCount} savol',
                      style: const TextStyle(
                          color: kTextMuted, fontSize: 11)),
                  const SizedBox(width: 8),
                  const Icon(Icons.timer_rounded,
                      size: 12, color: kTextMuted),
                  const SizedBox(width: 4),
                  Text('${test.timeLimitMinutes} min',
                      style: const TextStyle(
                          color: kTextMuted, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      context.go('/student/tests/${test.id}/play'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('Boshlash'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
