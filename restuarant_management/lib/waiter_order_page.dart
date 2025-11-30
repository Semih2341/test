import 'package:flutter/material.dart';
import 'api_service.dart';
import 'menu_item.dart';
import 'table_model.dart';

class WaiterOrderPage extends StatefulWidget {
  final RestaurantTable table;
  final String waiterName;
  const WaiterOrderPage(
      {super.key, required this.table, required this.waiterName});

  @override
  State<WaiterOrderPage> createState() => _WaiterOrderPageState();
}

class _WaiterOrderPageState extends State<WaiterOrderPage> {
  final ApiService _apiService = ApiService();
  List<MenuItem> menu = [];
  Map<MenuItem, int> cart = {};
  final TextEditingController noteController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    var data = await _apiService.getMenu();
    setState(() {
      menu = data;
      isLoading = false;
    });
  }

  void _addToCart(MenuItem item) {
    setState(() {
      cart[item] = (cart[item] ?? 0) + 1;
    });
  }

  void _removeFromCart(MenuItem item) {
    setState(() {
      if (cart.containsKey(item) && cart[item]! > 0) {
        cart[item] = cart[item]! - 1;
        if (cart[item] == 0) cart.remove(item);
      }
    });
  }

  Future<void> _submitOrder() async {
    if (cart.isEmpty) return;
    setState(() => isLoading = true);

    DateTime now = DateTime.now();

    List<String> productStrings = [];
    cart.forEach((item, qty) {
      productStrings.add("${qty}x ${item.name}");
    });

    await _apiService.addOrder({
      "table": widget.table.name,
      "time":
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
      "fullDate": now.toIso8601String(),
      "preview":
          productStrings.first + (productStrings.length > 1 ? "..." : ""),
      "note": noteController.text.trim(),
      "orderNo": "#${now.millisecondsSinceEpoch.toString().substring(8)}",
      "status": "Preparing",
      "products": productStrings,
      "waiter": widget.waiterName,
    });

    await _apiService.updateTableStatus(widget.table.id, true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Order Sent!"), backgroundColor: Colors.green));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("${widget.table.name} Order"),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: menu.length,
                    itemBuilder: (context, index) {
                      final item = menu[index];
                      int qty = cart[item] ?? 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(children: [
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(item.name,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    Text("${item.price} Ft",
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold))
                                  ])),
                              if (qty > 0) ...[
                                IconButton(
                                    onPressed: () => _removeFromCart(item),
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red)),
                                Text("$qty",
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold))
                              ],
                              IconButton(
                                  onPressed: () => _addToCart(item),
                                  icon: const Icon(Icons.add_circle,
                                      color: Colors.green, size: 32))
                            ])),
                      );
                    },
                  ),
          ),
          if (cart.isNotEmpty)
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, -5))
                ]),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                          prefixIcon:
                              const Icon(Icons.edit_note, color: Colors.orange),
                          hintText: "Add Note",
                          filled: true,
                          fillColor: Colors.orange.shade50,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none))),
                  const SizedBox(height: 16),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${cart.length} Sort",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12)),
                            onPressed: _submitOrder,
                            icon: const Icon(Icons.send),
                            label: const Text("SEND"))
                      ])
                ]))
        ],
      ),
    );
  }
}
