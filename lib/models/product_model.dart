class Product {
  final String id;
  final String name;
  final double price;
  final String? nutritionInfo;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.nutritionInfo,
    required this.stock,
  });

  factory Product.fromMap(String id, Map<dynamic, dynamic> data) {
    return Product(
      id: id,
      name: data['name'] as String? ?? 'Produto sem nome',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      nutritionInfo: data['nutritionInfo'] as String?,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
    );
  }
}