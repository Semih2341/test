class MenuItem {
  final String? id;
  final String name;
  final double price;
  final double cost;
  final String category;

  MenuItem(
      {this.id,
      required this.name,
      required this.price,
      required this.cost,
      required this.category});

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id']?.toString(),
      name: json['name'] ?? "No Name",
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      cost: (json['cost'] is num) ? (json['cost'] as num).toDouble() : 0.0,
      category: json['category'] ?? "General",
    );
  }

  Map<String, dynamic> toJson() =>
      {'name': name, 'price': price, 'cost': cost, 'category': category};
}
