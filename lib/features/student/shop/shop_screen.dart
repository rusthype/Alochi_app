import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
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
        title: const Text('Sotib olish?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: AppColors.accent, size: 16),
                const SizedBox(width: 4),
                Text('${item.price} tanga',
                    style: const TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Qoladi: ${balance - item.price} tanga',
                style: const TextStyle(color: AppColors.gray, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor'),
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
        ref.invalidate(_shopItemsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${item.name} muvaffaqiyatli sotib olindi!'),
            backgroundColor: AppColors.success,
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: AppColors.danger,
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
      appBar: AppBar(title: const Text("Do'kon")),
      body: Stack(
        children: [
          Column(
            children: [
              walletAsync.when(
                loading: () => const SizedBox(height: 100),
                error: (_, __) => const SizedBox.shrink(),
                data: (wallet) {
                  final coins = wallet['coins'] ?? wallet['balance'] ?? 0;
                  return Container(
                    margin: const EdgeInsets.all(AppSpacing.l),
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.brand,
                          AppColors.brand.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded,
                            color: Colors.white, size: 48),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$coins',
                                style: AppTextStyles.displayM.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900)),
                            Text('tanga',
                                style: AppTextStyles.caption.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8))),
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
                    _CategoryChip(
                      label: 'Hammasi',
                      value: null,
                      selected: selectedCat == null,
                      onSelected: (v) =>
                          ref.read(_selectedCategoryProvider.notifier).state = v,
                    ),
                    _CategoryChip(
                      label: 'Avatarlar',
                      value: 'avatar',
                      selected: selectedCat == 'avatar',
                      onSelected: (v) =>
                          ref.read(_selectedCategoryProvider.notifier).state = v,
                    ),
                    _CategoryChip(
                      label: 'Ramkalar',
                      value: 'frame',
                      selected: selectedCat == 'frame',
                      onSelected: (v) =>
                          ref.read(_selectedCategoryProvider.notifier).state = v,
                    ),
                    _CategoryChip(
                      label: 'Badgelar',
                      value: 'badge',
                      selected: selectedCat == 'badge',
                      onSelected: (v) =>
                          ref.read(_selectedCategoryProvider.notifier).state = v,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: itemsAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (e, _) => Center(
                      child: Text('Xatolik: $e',
                          style: const TextStyle(color: AppColors.danger))),
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
                        padding: const EdgeInsets.all(AppSpacing.l),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          childAspectRatio: 0.75,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) => _ShopItemCard(
                          item: items[i],
                          balance: balance,
                          onPurchase: () => _purchase(items[i], balance),
                          onSelect: () {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('${items[i].name} tanlandi!'),
                              backgroundColor: AppColors.brand,
                            ));
                          },
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
              colors: const [
                AppColors.accent,
                AppColors.brand,
                AppColors.success,
                AppColors.info
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final String? value;
  final bool selected;
  final Function(String?) onSelected;

  const _CategoryChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(value),
        selectedColor: AppColors.brand,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.ink,
          fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: BorderSide(
            color: selected ? AppColors.brand : AppColors.line,
          ),
        ),
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final int balance;
  final VoidCallback onPurchase;
  final VoidCallback onSelect;

  const _ShopItemCard({
    required this.item,
    required this.balance,
    required this.onPurchase,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = balance >= item.price;
    final isOwned = item.isOwned;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOwned ? AppColors.brand : AppColors.line,
          width: isOwned ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: item.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.broken_image, size: 24),
                        )
                      : const Center(
                          child: Icon(Icons.card_giftcard_rounded,
                              size: 40, color: AppColors.gray2),
                        ),
                ),
                if (isOwned)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        color: AppColors.accent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${item.price}',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: isOwned
                      ? ElevatedButton(
                          onPressed: onSelect,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brand,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            minimumSize: const Size(0, 36),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Tanlash'),
                        )
                      : ElevatedButton(
                          onPressed: canAfford ? onPurchase : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canAfford
                                ? AppColors.brand
                                : AppColors.gray3,
                            foregroundColor:
                                canAfford ? Colors.white : AppColors.gray,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            minimumSize: const Size(0, 36),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            canAfford ? 'Sotib olish' : 'Yetarli XP yo\'q',
                            style: const TextStyle(fontSize: 12),
                          ),
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
