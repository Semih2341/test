import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'menu_item.dart';
import 'api_service.dart';
import 'person.dart';

class MenuPage extends StatefulWidget {
  final Person currentUser;
  const MenuPage({super.key, required this.currentUser});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final ApiService _apiService = ApiService();
  List<MenuItem> menuItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => isLoading = true);
    var data = await _apiService.getMenu();
    if (mounted) {
      setState(() {
        menuItems = data;
        isLoading = false;
      });
    }
  }

  // --- DELETE CONFIRMATION DIALOG ---
  void _confirmDelete(MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product"),
        content: Text("Are you sure you want to delete '${item.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              _deleteItem(item.id!); // Perform deletion
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _deleteItem(String id) async {
    await _apiService.deleteMenuItem(id);
    _loadMenu();
  }

// --- ADDING A PRODUCT ---
  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final catCtrl = TextEditingController();

    String? priceError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Add New Product"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: "Name Of The Product")),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        decoration: InputDecoration(
                            labelText: "Sale Price",
                            hintText: "180",
                            errorText: priceError),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                        ],
                        onChanged: (val) =>
                            setDialogState(() => priceError = null),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: costCtrl,
                        decoration: const InputDecoration(
                            labelText: "Cost", hintText: "100"),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: catCtrl,
                    decoration: const InputDecoration(labelText: "Category")),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;

                  double? price = double.tryParse(priceCtrl.text);
                  double? cost = double.tryParse(costCtrl.text);

                  if (price == null || price <= 0) {
                    setDialogState(() => priceError = "Invalid Price");
                    return;
                  }

                  await _apiService.addMenuItem(MenuItem(
                      name: nameCtrl.text.trim(),
                      price: price,
                      cost: cost ?? 0.0,
                      category: catCtrl.text.isEmpty
                          ? "General"
                          : catCtrl.text.trim()));

                  if (mounted) {
                    Navigator.pop(context);
                    _loadMenu();
                  }
                },
                child: const Text("Add"),
              ),
            ],
          );
        });
      },
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              if (ModalRoute.of(context)?.settings.name != route)
                Navigator.pushReplacementNamed(context, route,
                    arguments: widget.currentUser);
            },
            child: Text(title, style: const TextStyle(fontSize: 16))));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                _drawerButton(context, "Menu", '/menu', isActive: true),
                _drawerButton(context, "Tables", '/manage_tables'),
                const Spacer(),
                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                        onPressed: _showAddDialog,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50)),
                        icon: const Icon(Icons.add),
                        label: const Text("Add Product"))),
                const SizedBox(height: 20)
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                double profit = item.price - item.cost;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: Text(item.name[0].toUpperCase())),
                    title: Text(item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        "Sale: ${item.price} Ft | Cost: ${item.cost} Ft | Profit: ${profit.toStringAsFixed(1)} Ft",
                        style: TextStyle(
                            color: profit > 0 ? Colors.green : Colors.red)),
                    trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(item)), // Changed here
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
