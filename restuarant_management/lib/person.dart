class Person {
  final String? id;
  final String name;
  final String role; // "Manager", "Waiter", "Kitchen"
  final String username;
  final String password;
  final String phone;
  final String address;
  final bool isActive;
  final List<Map<String, String?>> shifts;

  Person({
    this.id,
    required this.name,
    required this.role,
    required this.username,
    required this.password,
    required this.phone,
    required this.address,
    required this.isActive,
    required this.shifts,
  });

// Working hours calculator
  double get totalHours {
    double total = 0.0;
    DateTime now = DateTime.now();
    for (var shift in shifts) {
      if (shift['start'] != null) {
        DateTime start = DateTime.parse(shift['start']!);
        DateTime end =
            shift['end'] != null ? DateTime.parse(shift['end']!) : now;
        total += end.difference(start).inMinutes / 60.0;
      }
    }
    return double.parse(total.toStringAsFixed(1));
  }

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id']?.toString(),
      name: json['name'] ?? "",
      role: json['role'] ?? "",
      username: json['username'] ?? "",
      password: json['password'] ?? "",
      phone: json['phone'] ?? "",
      address: json['address'] ?? "",
      isActive: json['isActive'] ?? false,
      shifts: json['shifts'] != null
          ? List<Map<String, String?>>.from((json['shifts'] as List).map((e) =>
              {"start": e['start']?.toString(), "end": e['end']?.toString()}))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role,
      'username': username,
      'password': password,
      'phone': phone,
      'address': address,
      'isActive': isActive,
      'shifts': shifts,
    };
  }
}
