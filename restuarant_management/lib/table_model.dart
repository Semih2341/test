class RestaurantTable {
  final String id;
  final String name;
  final bool isOccupied;

  RestaurantTable(
      {required this.id, required this.name, required this.isOccupied});

  factory RestaurantTable.fromJson(Map<String, dynamic> json) {
    return RestaurantTable(
      id: json['id'].toString(),
      name: json['name'] ?? "Table",
      isOccupied: json['isOccupied'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'isOccupied': isOccupied};
}
