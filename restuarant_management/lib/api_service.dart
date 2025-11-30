import 'dart:convert';
import 'package:http/http.dart' as http;
import 'person.dart';
import 'menu_item.dart';
import 'table_model.dart';

class ApiService {
  static const String baseUrl = "http://localhost:3000";

  Map<String, String> get headers => {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      };

  // --- STAFF ---
  Future<List<Person>> getStaff(String role) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/staff'), headers: headers);
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<Person> allStaff =
            body.map((item) => Person.fromJson(item)).toList();
        return allStaff.where((p) => p.role == role).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> addPerson(Person person) async {
    await http.post(Uri.parse('$baseUrl/staff'),
        headers: headers, body: jsonEncode(person.toJson()));
  }

  Future<void> updatePerson(String id, Person updatedPerson) async {
    await http.put(Uri.parse('$baseUrl/staff/$id'),
        headers: headers, body: jsonEncode(updatedPerson.toJson()));
  }

  Future<void> deletePerson(String id) async {
    await http.delete(Uri.parse('$baseUrl/staff/$id'), headers: headers);
  }

  // --- LOGIN & SHIFT ---
  Future<Person?> login(String username, String password) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/staff?username=$username&password=$password'),
          headers: headers);
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        if (body.isNotEmpty) return Person.fromJson(body.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> startShift(Person person) async {
    if (person.id == null) return;
    List<Map<String, dynamic>> currentShifts = List.from(person.shifts);
    currentShifts.add({"start": DateTime.now().toIso8601String(), "end": null});
    await http.patch(Uri.parse('$baseUrl/staff/${person.id}'),
        headers: headers,
        body: jsonEncode({"isActive": true, "shifts": currentShifts}));
  }

  Future<void> endShift(Person person) async {
    if (person.id == null) return;
    List<Map<String, dynamic>> currentShifts = List.from(person.shifts);
    if (currentShifts.isNotEmpty && currentShifts.last['end'] == null) {
      currentShifts.last['end'] = DateTime.now().toIso8601String();
    }
    await http.patch(Uri.parse('$baseUrl/staff/${person.id}'),
        headers: headers,
        body: jsonEncode({"isActive": false, "shifts": currentShifts}));
  }

  // --- MENU ---
  Future<List<MenuItem>> getMenu() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/menu'), headers: headers);
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => MenuItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> addMenuItem(MenuItem item) async {
    await http.post(Uri.parse('$baseUrl/menu'),
        headers: headers, body: jsonEncode(item.toJson()));
  }

  Future<void> deleteMenuItem(String id) async {
    await http.delete(Uri.parse('$baseUrl/menu/$id'), headers: headers);
  }

  // --- ORDERS ---
  Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/orders'), headers: headers);
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> addOrder(Map<String, dynamic> order) async {
    await http.post(Uri.parse('$baseUrl/orders'),
        headers: headers, body: jsonEncode(order));
  }

  Future<void> updateOrder(String id, Map<String, dynamic> updates) async {
    await http.patch(Uri.parse('$baseUrl/orders/$id'),
        headers: headers, body: jsonEncode(updates));
  }

  Future<void> deleteOrder(String id) async {
    await http.delete(Uri.parse('$baseUrl/orders/$id'), headers: headers);
  }

  // --- TABLES ---
  Future<List<RestaurantTable>> getTables() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/tables'), headers: headers);
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => RestaurantTable.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> updateTableStatus(String id, bool isOccupied) async {
    await http.patch(Uri.parse('$baseUrl/tables/$id'),
        headers: headers, body: jsonEncode({"isOccupied": isOccupied}));
  }

  // --- ADDING TABLE ---
  Future<void> addTable(RestaurantTable table) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/tables'),
        headers: headers,
        body: jsonEncode(table.toJson()),
      );
    } catch (e) {
      print("Table Add Error: $e");
    }
  }

  // DELETING TABLE
  Future<void> deleteTable(String id) async {
    try {
      await http.delete(Uri.parse('$baseUrl/tables/$id'), headers: headers);
    } catch (e) {
      print("Table Delete Error: $e");
    }
  }
}
