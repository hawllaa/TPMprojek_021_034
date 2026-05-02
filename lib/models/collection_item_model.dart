class CollectionItemModel {
  final int id;
  final String pcId;
  final String name;
  final dynamic price;
  final String currency;
  final String imageUrl;

  CollectionItemModel({
    required this.id,
    required this.pcId,
    required this.name,
    required this.price,
    required this.currency,
    required this.imageUrl,
  });

  factory CollectionItemModel.fromMap(Map<String, dynamic> map) {
    final pc = map["pc_collections"] as Map<String, dynamic>?; 

    return CollectionItemModel(
      id: map["id"] as int,
      pcId: map["pc_id"].toString(),
      name: pc?["name"] ?? "",
      price: pc?["price"] ?? 0,
      currency: pc?["currency"] ?? "",
      imageUrl: pc?["image_url"] ?? "",
    );
  }

  String get formattedPrice {
    if (currency == "KRW") return "₩$price";
    return "$currency $price";
  }
}
