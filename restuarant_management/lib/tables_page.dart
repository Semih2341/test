import 'package:flutter/material.dart';
import 'api_service.dart';
import 'table_model.dart';
import 'person.dart';

class TablesPage extends StatefulWidget {
  final Person currentUser;
  const TablesPage({super.key, required this.currentUser});

  @override
  State<TablesPage> createState() => _TablesPageState();
}

class _TablesPageState extends State<TablesPage> {
  final ApiService _apiService = ApiService();
  List<RestaurantTable> tables = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() => isLoading = true);
    var data = await _apiService.getTables();
    if (mounted) {
      setState(() {
        tables = data;
        isLoading = false;
      });
    }
  }

  void _deleteTable(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Table"),
        content: Text("Are you sure you want to remove the table $name?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await _apiService.deleteTable(id);
              if (mounted) {
                Navigator.pop(context);
                _loadTables();
              }
            },
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  void _showAddTableDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Table"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: "Table Name",
                  hintText: "Ex: Table 5 or Garden 3",
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            const Text(
              "Tip: Names that start with 'Garden' or 'G' automatically appear in the Garden section.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _apiService.addTable(RestaurantTable(
                    id: "", name: nameController.text, isOccupied: false));

                if (mounted) {
                  Navigator.pop(context);
                  _loadTables();
                }
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Widget _drawerButton(BuildContext context, String title, String route,
      {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            elevation: 0,
            alignment: Alignment.centerLeft,
            minimumSize: const Size(double.infinity, 45),
            backgroundColor:
                isActive ? Colors.blue.shade50 : Colors.transparent,
            foregroundColor: isActive ? Colors.blue : Colors.black87,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        onPressed: () {
          if (ModalRoute.of(context)?.settings.name != route) {
            Navigator.pushReplacementNamed(context, route,
                arguments: widget.currentUser);
          }
        },
        child: Text(title, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 220,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text("Manager Panel",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Divider(),
                const SizedBox(height: 20),
                _drawerButton(context, "Dashboard", '/dashboard'),
                _drawerButton(context, "Orders", '/orders'),
                _drawerButton(context, "Waiters", '/waiters'),
                _drawerButton(context, "Kitchen", '/kitchen_list'),
                _drawerButton(context, "Menu", '/menu'),
                _drawerButton(context, "Tables", '/manage_tables',
                    isActive: true),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50)),
                    onPressed: _showAddTableDialog,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Table"),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: table.isOccupied
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                      child: Icon(Icons.table_bar,
                          color: table.isOccupied ? Colors.red : Colors.green),
                    ),
                    title: Text(table.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(table.isOccupied ? "Occupied" : "Empty"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteTable(table.id, table.name),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
