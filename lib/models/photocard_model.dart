class PhotocardModel {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final String currency;
  final double lat;
  final double lng;
  final double? distanceVal;
  final String? distance;
  final bool isCollected;

  PhotocardModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.currency,
    required this.lat,
    required this.lng,
    this.distanceVal,
    this.distance,
    this.isCollected = false,
  });

  factory PhotocardModel.fromMap(Map<String, dynamic> map) {
    return PhotocardModel(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      imageUrl: map['image_url'] ?? '',
      price: map['price'] == null
        ? 0
        : (map['price'] as num).toDouble(),
      currency: map['currency'] ?? '',
      lat: (map['lat'] as num).toDouble(),
      lng: (map['long'] as num).toDouble(),
      distanceVal: map['distance_val'] != null
          ? (map['distance_val'] as num).toDouble()
          : null,
      distance: map['distance'],
      isCollected: map['is_collected'] ?? false,
    );
  }

  PhotocardModel copyWith({
    double? distanceVal,
    String? distance,
    bool? isCollected,
  }) {
    return PhotocardModel(
      id: id,
      name: name,
      imageUrl: imageUrl,
      price: price,
      currency: currency,
      lat: lat,
      lng: lng,
      distanceVal: distanceVal ?? this.distanceVal,
      distance: distance ?? this.distance,
      isCollected: isCollected ?? this.isCollected,
    );
  }

  String get priceWithCurrency =>
    '${price.toStringAsFixed(2)} $currency';
}
