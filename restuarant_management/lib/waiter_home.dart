import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'table_model.dart';
import 'waiter_order_page.dart';
import 'person.dart';

class WaiterHome extends StatefulWidget {
  final Person currentWaiter;
  const WaiterHome({super.key, required this.currentWaiter});

  @override
  State<WaiterHome> createState() => _WaiterHomeState();
}

class _WaiterHomeState extends State<WaiterHome> {
  int _currentIndex = 0;

  // --- GÜVENLİ ÇIKIŞ İŞLEMİ ---
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("End The Shift"),
        content: const Text(
            "Do you want to log out of the system and end the shift?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text("LogOut"),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    final ApiService api = ApiService();
    await api.endShift(widget.currentWaiter);
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Waiter Panel", style: TextStyle(fontSize: 14)),
            Text(widget.currentWaiter.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "End The Shift",
            onPressed: _confirmLogout, // Onay kutusunu açar
          )
        ],
      ),
      body: _currentIndex == 0
          ? WaiterTablesView(waiterName: widget.currentWaiter.name)
          : WaiterOrdersView(waiterName: widget.currentWaiter.name),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.orange,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.table_restaurant), label: "Tables"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "My"),
        ],
      ),
    );
  }
}

// --- 1. SEKME: MASALAR GÖRÜNÜMÜ ---
class WaiterTablesView extends StatefulWidget {
  final String waiterName;
  const WaiterTablesView({super.key, required this.waiterName});

  @override
  State<WaiterTablesView> createState() => _WaiterTablesViewState();
}

class _WaiterTablesViewState extends State<WaiterTablesView> {
  final ApiService _apiService = ApiService();
  List<RestaurantTable> tables = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    var data = await _apiService.getTables();
    if (mounted) {
      setState(() {
        tables = data;
        isLoading = false;
      });
    }
  }

  void _showOccupiedTableOptions(RestaurantTable table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${table.name} operations"),
        content: const Text("What would you like to do?"),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text("Additional Order"),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _goToOrderPage(table);
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.cleaning_services),
            label: const Text("Clear the Table"),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              await _apiService.updateTableStatus(table.id, false);
              if (mounted) {
                Navigator.pop(context);
                _loadTables();
              }
            },
          ),
        ],
      ),
    );
  }

  void _goToOrderPage(RestaurantTable table) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                WaiterOrderPage(table: table, waiterName: widget.waiterName)));
    _loadTables();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        return GestureDetector(
          onTap: () => table.isOccupied
              ? _showOccupiedTableOptions(table)
              : _goToOrderPage(table),
          child: Container(
            decoration: BoxDecoration(
                color: table.isOccupied
                    ? Colors.red.shade100
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: table.isOccupied ? Colors.red : Colors.green,
                    width: 2),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(2, 2))
                ]),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.table_restaurant,
                  size: 40,
                  color: table.isOccupied ? Colors.red : Colors.green),
              const SizedBox(height: 8),
              Text(table.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(table.isOccupied ? "occupied" : "EMPTY",
                  style: TextStyle(
                      fontSize: 12,
                      color: table.isOccupied
                          ? Colors.red.shade900
                          : Colors.green.shade900,
                      fontWeight: FontWeight.bold))
            ]),
          ),
        );
      },
    );
  }
}

class WaiterOrdersView extends StatefulWidget {
  final String waiterName;
  const WaiterOrdersView({super.key, required this.waiterName});

  @override
  State<WaiterOrdersView> createState() => _WaiterOrdersViewState();
}

class _WaiterOrdersViewState extends State<WaiterOrdersView> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> myOrders = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadMyOrders();
    _timer = Timer.periodic(
        const Duration(seconds: 5), (timer) => _checkOrderUpdates());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadMyOrders() async {
    var allOrders = await _apiService.getOrders();
    if (mounted) {
      setState(() {
        myOrders = allOrders
            .where((o) =>
                o['waiter'] == widget.waiterName && o['status'] != 'Completed')
            .toList();
      });
    }
  }

  Future<void> _checkOrderUpdates() async {
    var freshOrders = await _apiService.getOrders();
    for (var fresh in freshOrders) {
      var old =
          myOrders.firstWhere((o) => o['id'] == fresh['id'], orElse: () => {});
      if (old.isNotEmpty &&
          old['status'] == 'Preparing' &&
          fresh['status'] == 'Ready') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("🔔 ${fresh['table']} Order READY!"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
    if (mounted) {
      setState(() {
        myOrders = freshOrders
            .where((o) =>
                o['waiter'] == widget.waiterName && o['status'] != 'Completed')
            .toList();
      });
    }
  }

  void _showOrderOptions(Map<String, dynamic> order) {
    bool isReady = order['status'] == 'Ready'; // Durum kontrolü

    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.check_circle,
                color: isReady ? Colors.green : Colors.grey),
            title: Text(
              'Delivered (Complete)',
              style: TextStyle(
                  color: isReady ? Colors.black : Colors.grey,
                  fontWeight: isReady ? FontWeight.bold : FontWeight.normal),
            ),
            subtitle: isReady
                ? null
                : const Text("Waiting for kitchen approval...",
                    style: TextStyle(fontSize: 12, color: Colors.red)),
            onTap: () async {
              if (!isReady) {
                Navigator.pop(context); // Menüyü kapat
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        "⛔ ERROR: The order has not been prepared in the kitchen yet!"),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }

              await _apiService
                  .updateOrder(order['id'].toString(), {"status": "Completed"});
              if (mounted) {
                Navigator.pop(context);
                _loadMyOrders();
              }
            },
          ),

          const Divider(),

          // 2. SİLME / İPTAL BUTONU
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.red),
            title: const Text('Cancel Order'),
            onTap: () async {
              await _apiService.deleteOrder(order['id'].toString());
              if (mounted) {
                Navigator.pop(context);
                _loadMyOrders();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (myOrders.isEmpty) {
      return const Center(child: Text("You have no active orders."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myOrders.length,
      itemBuilder: (context, index) {
        final order = myOrders[index];
        bool isReady = order['status'] == 'Ready';

        return Card(
          elevation: 3,
          color: isReady ? Colors.green.shade50 : Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () => _showOrderOptions(order),
            leading: CircleAvatar(
              backgroundColor: isReady ? Colors.green : Colors.orange,
              child: Icon(isReady ? Icons.check : Icons.access_time,
                  color: Colors.white),
            ),
            title: Text(order['table'],
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order['preview'], style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: isReady ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(order['status'],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                if (order['note'] != "")
                  Text("Note: ${order['note']}",
                      style: const TextStyle(
                          color: Colors.red, fontStyle: FontStyle.italic)),
              ],
            ),
            trailing: const Icon(Icons.more_vert),
          ),
        );
      },
    );
  }
}
