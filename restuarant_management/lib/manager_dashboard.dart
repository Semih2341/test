import 'package:flutter/material.dart';
import 'api_service.dart';
import 'table_model.dart';
import 'person.dart';
import 'menu_item.dart';

class DashboardHome extends StatefulWidget {
  final Person currentUser;
  const DashboardHome({super.key, required this.currentUser});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  double totalSales = 0;
  double totalCost = 0;
  double totalProfit = 0;

  int totalOrderCount = 0;
  int activeCustomers = 0;
  int activeWaiters = 0;
  int activeKitchenStaff = 0;

  final ApiService _apiService = ApiService();

  final ScrollController _summaryScrollController = ScrollController();
  final ScrollController _tableScrollController = ScrollController();
  final ScrollController _activeInfoScrollController = ScrollController();

  List<RestaurantTable> allTables = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    var orders = await _apiService.getOrders();
    var waiters = await _apiService.getStaff("Waiter");
    var kitchen = await _apiService.getStaff("Kitchen");
    var tables = await _apiService.getTables();
    var menu = await _apiService.getMenu();

    double sales = 0;
    double costs = 0;
    int todaysOrders = 0;

    DateTime now = DateTime.now();
    String todayStr = "${now.year}-${now.month}-${now.day}";

    for (var order in orders) {
      if (order['fullDate'] != null) {
        try {
          DateTime orderDate = DateTime.parse(order['fullDate']);
          String orderDayStr =
              "${orderDate.year}-${orderDate.month}-${orderDate.day}";
          if (orderDayStr != todayStr) continue;
        } catch (e) {
          continue;
        }
      } else {
        continue;
      }

      todaysOrders++;

      List products = order['products'] is List ? order['products'] : [];

      for (String productStr in products) {
        try {
          List<String> parts = productStr.split("x ");
          if (parts.length >= 2) {
            int qty = int.parse(parts[0]);
            String name = parts[1].trim();

            var menuItem = menu.firstWhere((m) => m.name == name,
                orElse: () =>
                    MenuItem(name: "", price: 0, cost: 0, category: ""));

            if (order['status'] == 'Completed') {
              sales += menuItem.price * qty;
              costs += menuItem.cost * qty;
            }
          }
        } catch (e) {
          print("Calculation error: $productStr -> $e");
        }
      }
    }

    if (mounted) {
      setState(() {
        allTables = tables;

        totalSales = sales;
        totalCost = costs;
        totalProfit = sales - costs;

        totalOrderCount = todaysOrders;
        activeCustomers = tables.where((t) => t.isOccupied).length * 2;
        activeWaiters = waiters.where((p) => p.isActive).length;
        activeKitchenStaff = kitchen.where((p) => p.isActive).length;
      });
    }
  }

  void _logout() async {
    await _apiService.endShift(widget.currentUser);
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  void _handleTableTap(RestaurantTable table) async {
    String action = table.isOccupied ? "clear" : "fill";

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Table Status"),
        content: Text("Do you want to $action ${table.name}"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: table.isOccupied ? Colors.green : Colors.red,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: Text(table.isOccupied ? "clear" : "fill"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _apiService.updateTableStatus(table.id, !table.isOccupied);
      _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    int emptyTables = allTables.where((t) => !t.isOccupied).length;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Row(
        children: [
          // --- Drawer ---
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
                _drawerButton(context, "Dashboard", '/dashboard',
                    isActive: true),
                _drawerButton(context, "Orders", '/orders'),
                _drawerButton(context, "Waiters", '/waiters'),
                _drawerButton(context, "Kitchen", '/kitchen_list'),
                _drawerButton(context, "Menu", '/menu'),
                _drawerButton(context, "Tables", '/manage_tables'),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                      elevation: 0,
                    ),
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text("LogOut",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // --- Main Content ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Scrollbar(
                  controller: _summaryScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _summaryScrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _summaryCard(
                            "Total Turnover",
                            "${totalSales.toStringAsFixed(0)} Ft",
                            Icons.account_balance_wallet,
                            Colors.blue),
                        const SizedBox(width: 20),
                        _summaryCard(
                            "Total Cost",
                            "${totalCost.toStringAsFixed(0)} Ft",
                            Icons.shopping_bag,
                            Colors.orange),
                        const SizedBox(width: 20),
                        _summaryCard(
                            totalProfit >= 0 ? "Net Profit" : "Loss",
                            "${totalProfit.abs().toStringAsFixed(0)} Ft",
                            totalProfit >= 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            totalProfit >= 0 ? Colors.green : Colors.red),
                        const SizedBox(width: 20),
                        _summaryCard("Empty Tables", "$emptyTables",
                            Icons.table_bar, Colors.teal),
                        const SizedBox(width: 20),
                        _summaryCard("Today's Order", "$totalOrderCount",
                            Icons.receipt, Colors.purple),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text("Table States",
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Scrollbar(
                  controller: _tableScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _tableScrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: screenWidth > 1200 ? screenWidth - 300 : 800,
                      child: _buildTableGrid(),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Scrollbar(
                  controller: _activeInfoScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _activeInfoScrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _summaryCard("Estimated Customer", "$activeCustomers",
                            Icons.groups, Colors.indigo),
                        const SizedBox(width: 20),
                        _summaryCard("Active Waiter", "$activeWaiters",
                            Icons.badge, Colors.teal),
                        const SizedBox(width: 20),
                        _summaryCard("Active Chef", "$activeKitchenStaff",
                            Icons.soup_kitchen, Colors.redAccent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
          backgroundColor: isActive ? Colors.blue.shade50 : Colors.transparent,
          foregroundColor: isActive ? Colors.blue : Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
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

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 280,
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 6,
              offset: const Offset(2, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey)),
                const SizedBox(height: 8),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableGrid() {
    final gardenTables = allTables
        .where((t) =>
            t.name.toLowerCase().contains("garden") || t.name.startsWith("G"))
        .toList();
    final insideTables = allTables
        .where((t) =>
            !t.name.toLowerCase().contains("garden") && !t.name.startsWith("G"))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle("Garden"),
        if (gardenTables.isEmpty)
          const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("There is no table in the garden.",
                  style: TextStyle(color: Colors.grey)))
        else
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5),
              itemCount: gardenTables.length,
              itemBuilder: (context, index) =>
                  _buildSingleTable(gardenTables[index])),
        const SizedBox(height: 20),
        _sectionTitle("Inside"),
        if (insideTables.isEmpty)
          const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("There is no table inside.",
                  style: TextStyle(color: Colors.grey)))
        else
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5),
              itemCount: insideTables.length,
              itemBuilder: (context, index) =>
                  _buildSingleTable(insideTables[index])),
      ],
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(title.contains("Garden") ? Icons.deck : Icons.roofing,
                color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Divider(),
            )
          ],
        ),
      );

  Widget _buildSingleTable(RestaurantTable table) {
    return GestureDetector(
      onTap: () => _handleTableTap(table),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
            color: table.isOccupied
                ? Colors.redAccent.shade100
                : Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: table.isOccupied ? Colors.red : Colors.green, width: 2),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(2, 2))
            ]),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(table.name,
                  style: TextStyle(
                      color: table.isOccupied
                          ? Colors.red.shade900
                          : Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 4),
              Text(table.isOccupied ? "Full" : "EMPTY",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: table.isOccupied
                          ? Colors.red
                          : Colors.green.shade900))
            ],
          ),
        ),
      ),
    );
  }
}
