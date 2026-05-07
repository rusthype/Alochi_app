import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../core/api/student_api.dart';
import '../../../core/models/shop_item.dart';

final _walletProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return StudentApi().getWallet();
});

final _selectedCategoryProvider = StateProvider<String?>((ref) => null);

final _shopItemsProvider = FutureProvider<List<ShopItem>>((ref) async {
  final cat = ref.watch(_selectedCategoryProvider);
  return StudentApi().getShopItems(category: cat);
});

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _purchase(ShopItem item, int balance) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBgCard,
        title:
            const Text('Sotib olish?', style: TextStyle(color: kTextPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name,
                style: const TextStyle(
                    color: kTextPrimary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: kYellow, size: 16),
                const SizedBox(width: 4),
                Text('${item.price} tanga',
                    style: const TextStyle(color: kYellow)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Qoladi: ${balance - item.price} tanga',
                style: const TextStyle(color: kTextMuted, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor', style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tasdiqlash'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await StudentApi().purchaseItem(item.slug);
        _confetti.play();
        ref.invalidate(_walletProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${item.name} muvaffaqiyatli sotib olindi!'),
            backgroundColor: kGreen,
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: kRed,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(_walletProvider);
    final itemsAsync = ref.watch(_shopItemsProvider);
    final selectedCat = ref.watch(_selectedCategoryProvider);

    return Scaffold(
      backgroundColor: kBgMain,
      appBar: AppBar(title: const Text("Do'kon")),
      body: Stack(
        children: [
          Column(
            children: [
              walletAsync.when(
                loading: () => const SizedBox(height: 80),
                error: (_, __) => const SizedBox.shrink(),
                data: (wallet) {
                  final coins = wallet['coins'] ?? wallet['balance'] ?? 0;
                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        kYellow.withValues(alpha: 0.2),
                        kOrange.withValues(alpha: 0.2)
                      ]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kYellow.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded,
                            color: kYellow, size: 40),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$coins',
                                style: const TextStyle(
                                    color: kYellow,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900)),
                            const Text('tanga',
                                style: TextStyle(
                                    color: kTextSecondary, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Barchasi'),
                        selected: selectedCat == null,
                        onSelected: (_) => ref
                            .read(_selectedCategoryProvider.notifier)
                            .state = null,
                        selectedColor: kOrange,
                      ),
                    ),
                    ...['badge', 'avatar', 'boost', 'decoration']
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(c),
                                selected: selectedCat == c,
                                onSelected: (_) => ref
                                    .read(_selectedCategoryProvider.notifier)
                                    .state = c,
                                selectedColor: kOrange,
                              ),
                            )),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: itemsAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (e, _) => Center(
                      child: Text('Xatolik: $e',
                          style: const TextStyle(color: kRed))),
                  data: (items) {
                    if (items.isEmpty) {
                      return const AlochiEmptyState(
                          title: 'Mahsulotlar topilmadi');
                    }
                    final balance = (walletAsync.value?['coins'] ??
                        walletAsync.value?['balance'] ??
                        0) as int;
                    return LayoutBuilder(builder: (ctx, constraints) {
                      final cols = constraints.maxWidth > 600 ? 3 : 2;
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          childAspectRatio: 0.85,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) => _ShopItemCard(
                          item: items[i],
                          balance: balance,
                          onPurchase: () => _purchase(items[i], balance),
                        ),
                      );
                    });
                  },
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [kOrange, kGreen, kYellow, kPurple, kBlue],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final int balance;
  final VoidCallback onPurchase;
  const _ShopItemCard(
      {required this.item, required this.balance, required this.onPurchase});

  @override
  Widget build(BuildContext context) {
    final canAfford = balance >= item.price;
    return Container(
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBgBorder),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: kBgMain,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image, size: 24),
                    )
                  : const Center(
                      child: Icon(Icons.card_giftcard_rounded,
                          size: 48, color: kTextMuted),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(item.name,
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        color: kYellow, size: 14),
                    const SizedBox(width: 4),
                    Text('${item.price}',
                        style: const TextStyle(
                            color: kYellow, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canAfford ? onPurchase : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Sotib olish'),
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
