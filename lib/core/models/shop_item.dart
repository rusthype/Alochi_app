class ShopItem {
  final String id;
  final String slug;
  final String name;
  final String? description;
  final int price;
  final String? imageUrl;
  final String? category;
  final bool isOwned;

  const ShopItem({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.category,
    this.isOwned = false,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id']?.toString() ?? '',
      slug: json['slug'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      price: json['price'] ?? 0,
      imageUrl: json['image'],
      category: json['category'],
      isOwned: json['is_owned'] == true,
    );
  }
}

class Purchase {
  final String id;
  final ShopItem item;
  final int pricePaid;
  final DateTime purchasedAt;

  const Purchase({
    required this.id,
    required this.item,
    required this.pricePaid,
    required this.purchasedAt,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id']?.toString() ?? '',
      item: ShopItem.fromJson(json['item'] as Map<String, dynamic>? ?? {}),
      pricePaid: json['price_paid'] ?? 0,
      purchasedAt:
          DateTime.tryParse(json['purchased_at'] ?? '') ?? DateTime.now(),
    );
  }
}
