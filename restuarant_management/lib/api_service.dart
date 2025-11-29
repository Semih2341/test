import 'dart:convert';
import 'package:http/http.dart' as http;
import 'person.dart';
import 'menu_item.dart';
import 'table_model.dart';

class ApiService {
  //localHost
  static const String baseUrl =
      "https://rebecca-nondecayed-hortencia.ngrok-free.dev";

  // --- STAFF ---
  Future<List<Person>> getStaff(String role) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/staff'));
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
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(person.toJson()));
  }

  Future<void> updatePerson(String id, Person updatedPerson) async {
    await http.put(Uri.parse('$baseUrl/staff/$id'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updatedPerson.toJson()));
  }

  Future<void> deletePerson(String id) async {
    await http.delete(Uri.parse('$baseUrl/staff/$id'));
  }

  // --- LOGIN & SHIFT ---
  Future<Person?> login(String username, String password) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/staff?username=$username&password=$password'));
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
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"isActive": true, "shifts": currentShifts}));
  }

  Future<void> endShift(Person person) async {
    if (person.id == null) return;
    List<Map<String, dynamic>> currentShifts = List.from(person.shifts);
    if (currentShifts.isNotEmpty && currentShifts.last['end'] == null) {
      currentShifts.last['end'] = DateTime.now().toIso8601String();
    }
    await http.patch(Uri.parse('$baseUrl/staff/${person.id}'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"isActive": false, "shifts": currentShifts}));
  }

  // --- MENU ---
  Future<List<MenuItem>> getMenu() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/menu'));
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
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(item.toJson()));
  }

  Future<void> deleteMenuItem(String id) async {
    await http.delete(Uri.parse('$baseUrl/menu/$id'));
  }

  // --- ORDERS ---
  Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders'));
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
        headers: {"Content-Type": "application/json"}, body: jsonEncode(order));
  }

  Future<void> updateOrder(String id, Map<String, dynamic> updates) async {
    await http.patch(Uri.parse('$baseUrl/orders/$id'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updates));
  }

  Future<void> deleteOrder(String id) async {
    await http.delete(Uri.parse('$baseUrl/orders/$id'));
  }

  // --- TABLES ---
  Future<List<RestaurantTable>> getTables() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tables'));
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
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"isOccupied": isOccupied}));
  }

  // --- ADDING TABLE ---
  Future<void> addTable(RestaurantTable table) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/tables'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(table.toJson()),
      );
    } catch (e) {
      print("Masa Ekleme Hatası: $e");
    }
  }

  // DELETING TABLE
  Future<void> deleteTable(String id) async {
    try {
      await http.delete(Uri.parse('$baseUrl/tables/$id'));
    } catch (e) {
      print("Masa Silme Hatası: $e");
    }
  }
}
