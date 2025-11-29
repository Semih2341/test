import 'package:flutter/material.dart';
import 'api_service.dart';
import 'person.dart';

class OrdersPage extends StatefulWidget {
  final Person currentUser;
  const OrdersPage({super.key, required this.currentUser});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => isLoading = true);
    var data = await _apiService.getOrders();
    if (mounted) {
      setState(() {
        orders = data;
        isLoading = false;
      });
    }
  }

  void _deleteOrder(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Approval"),
        content: const Text("Are you sure you want to delete the order?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await _apiService.deleteOrder(id);
              if (mounted) {
                Navigator.pop(context);
                _loadOrders();
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Preparing":
        return Colors.red.shade100;
      case "Ready":
        return Colors.green.shade100;
      case "Completed":
        return Colors.grey.shade300;
      default:
        return Colors.white;
    }
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                _drawerButton(context, "Dashboard", '/dashboard'),
                _drawerButton(context, "Orders", '/orders', isActive: true),
                _drawerButton(context, "Waiters", '/waiters'),
                _drawerButton(context, "Kitchen", '/kitchen_list'),
                _drawerButton(context, "Menu", '/menu'),
                _drawerButton(context, "Tables", '/manage_tables'),
                const Spacer(),
              ],
            ),
          ),

          // --- Main Content ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                String productsDisplay;
                if (order['products'] is List) {
                  productsDisplay = (order['products'] as List).join(", ");
                } else {
                  productsDisplay = order['products'].toString();
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: _getStatusColor(order["status"]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ]),
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 16),

                    // HEADER
                    title: Row(
                      children: [
                        Text(order["table"],
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 16),
                        const SizedBox(
                            height: 24,
                            child: VerticalDivider(color: Colors.grey)),
                        const SizedBox(width: 16),
                        Text(order["time"] ?? "--",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87)),
                        const SizedBox(width: 16),
                        const SizedBox(
                            height: 24,
                            child: VerticalDivider(color: Colors.grey)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(order["preview"],
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600))),
                              if (order["note"] != "") ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.edit_note,
                                    size: 20, color: Colors.orange),
                              ]
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        const SizedBox(
                            height: 24,
                            child: VerticalDivider(color: Colors.grey)),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(order["orderNo"],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            Text(order["status"],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _deleteOrder(order['id'].toString()),
                        ),
                      ],
                    ),

                    // Details
                    children: [
                      const Divider(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Order Content:",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(productsDisplay,
                                    style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Waiter: ${order["waiter"]}",
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                                if (order["note"] != "")
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                          color: Colors.yellow.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Text("Note: ${order["note"]}",
                                          style: const TextStyle(fontSize: 14)),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        ],
                      )
                    ],
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
