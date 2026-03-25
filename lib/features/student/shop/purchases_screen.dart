import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/api/student_api.dart';
import '../../../core/models/shop_item.dart';

final _purchasesProvider =
    FutureProvider<List<Purchase>>((ref) async {
  return StudentApi().getPurchases();
});

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_purchasesProvider);
    return Scaffold(
      backgroundColor: kBgMain,
      appBar: AppBar(title: const Text('Mening xaridlarim')),
      body: async.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(
            child: Text('Xatolik: $e',
                style: const TextStyle(color: kRed))),
        data: (purchases) {
          if (purchases.isEmpty) {
            return const EmptyState(
                message: 'Hali hech narsa xarid qilmadingiz',
                icon: Icons.shopping_bag_outlined);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: purchases.length,
            itemBuilder: (ctx, i) {
              final p = purchases[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kBgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kBgBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: kBgMain,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: p.item.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: p.item.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                              errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 24),
                            )
                          : const Icon(
                              Icons.card_giftcard_rounded,
                              color: kTextMuted),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(p.item.name,
                              style: const TextStyle(
                                  color: kTextPrimary,
                                  fontWeight: FontWeight.w600)),
                          Text(
                              '${p.purchasedAt.day}.${p.purchasedAt.month}.${p.purchasedAt.year}',
                              style: const TextStyle(
                                  color: kTextMuted,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded,
                            color: kYellow, size: 14),
                        const SizedBox(width: 4),
                        Text('${p.pricePaid}',
                            style: const TextStyle(
                                color: kYellow,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
