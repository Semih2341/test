import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'person.dart';
import 'api_service.dart';

class KitchenPage extends StatefulWidget {
  final Person currentUser;
  const KitchenPage({super.key, required this.currentUser});

  @override
  State<KitchenPage> createState() => _KitchenPageState();
}

class _KitchenPageState extends State<KitchenPage> {
  final ApiService _apiService = ApiService();
  List<Person> kitchenStaff = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => isLoading = true);
    var data = await _apiService.getStaff("Kitchen");
    if (mounted) {
      setState(() {
        kitchenStaff = data;
        isLoading = false;
      });
    }
  }

  void _deleteStaff(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Staff"),
        content: Text("Are you sure you want to remove $name"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await _apiService.deletePerson(id);
              if (mounted) {
                Navigator.pop(context);
                _loadStaff();
              }
            },
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  // --- EKLEME VE DÜZENLEME ---
  void _showPersonDialog({Person? existingPerson}) {
    final nameCtrl = TextEditingController(text: existingPerson?.name ?? "");
    final userCtrl =
        TextEditingController(text: existingPerson?.username ?? "");
    final passCtrl =
        TextEditingController(text: existingPerson?.password ?? "");
    final phoneCtrl = TextEditingController(text: existingPerson?.phone ?? "");
    final addrCtrl = TextEditingController(text: existingPerson?.address ?? "");

    bool isEdit = existingPerson != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Edit Chef" : "New Kitchen Staff"),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8)),
              child: const Text("Role: KITCHEN (Kitchen)",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.deepOrange)),
            ),
            const SizedBox(height: 10),
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: "Name Surname",
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(
                controller: userCtrl,
                decoration: const InputDecoration(
                    labelText: "User Name",
                    prefixIcon: Icon(Icons.account_circle),
                    border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(
                controller: passCtrl,
                decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))
                ],
                decoration: const InputDecoration(
                    labelText: "Phone",
                    hintText: "+36123...",
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(
                    labelText: "Address",
                    prefixIcon: Icon(Icons.home),
                    border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty &&
                  userCtrl.text.isNotEmpty &&
                  passCtrl.text.isNotEmpty) {
                Person newPerson = Person(
                  id: isEdit ? existingPerson.id : null,
                  name: nameCtrl.text,
                  role: "Kitchen",
                  username: userCtrl.text,
                  password: passCtrl.text,
                  phone: phoneCtrl.text,
                  address: addrCtrl.text,
                  isActive: isEdit ? existingPerson.isActive : false,
                  shifts: isEdit ? existingPerson.shifts : [],
                );

                if (isEdit) {
                  await _apiService.updatePerson(existingPerson.id!, newPerson);
                } else {
                  await _apiService.addPerson(newPerson);
                }

                if (mounted) {
                  Navigator.pop(context);
                  _loadStaff();
                }
              }
            },
            child: Text(isEdit ? "Update" : "Save"),
          ),
        ],
      ),
    );
  }

  void _showPersonDetails(Person p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(p.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
                leading: const Icon(Icons.phone),
                title: Text(p.phone.isEmpty ? "No Phone" : p.phone),
                contentPadding: EdgeInsets.zero),
            ListTile(
                leading: const Icon(Icons.home),
                title: Text(p.address.isEmpty ? "No Address" : p.address),
                contentPadding: EdgeInsets.zero),
            const Divider(),
            Text("User: ${p.username}"),
            Text("Password: ${p.password}"),
            const Divider(),
            Text("Working hours: ${p.totalHours} Hour",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Status: ${p.isActive ? 'In Shift' : 'Out Of Shift'}",
                style:
                    TextStyle(color: p.isActive ? Colors.green : Colors.red)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"))
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              if (ModalRoute.of(context)?.settings.name != route) {
                Navigator.pushReplacementNamed(context, route,
                    arguments: widget.currentUser);
              }
            },
            child: Text(title, style: const TextStyle(fontSize: 16))));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    int total = kitchenStaff.length;
    int active = kitchenStaff.where((w) => w.isActive).length;
    int inactive = total - active;

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
                _drawerButton(context, "Kitchen", '/kitchen_list',
                    isActive: true),
                _drawerButton(context, "Menu", '/menu'),
                _drawerButton(context, "Tables", '/manage_tables'),
                const Spacer(),
                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50)),
                        onPressed: () => _showPersonDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text("Add Chef"))),
                const SizedBox(height: 20)
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(children: [
                  _buildSummaryCard(
                      "Total Chef", total.toString(), Colors.orange),
                  const SizedBox(width: 16),
                  _buildSummaryCard("Active", active.toString(), Colors.green),
                  const SizedBox(width: 16),
                  _buildSummaryCard(
                      "Break/Exit", inactive.toString(), Colors.grey)
                ]),
                const SizedBox(height: 30),
                const Text("Kitchen Staff",
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (kitchenStaff.isEmpty)
                  const Center(child: Text("No record."))
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 250,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16),
                    itemCount: kitchenStaff.length,
                    itemBuilder: (context, index) => _buildPersonCard(
                      kitchenStaff[index],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String val, Color color) {
    return Expanded(
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 3))
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.bold)),
            Text(val,
                style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold, color: color))
          ],
        ),
      ),
    );
  }

  Widget _buildPersonCard(Person p) {
    return InkWell(
      onTap: () => _showPersonDetails(p),
      child: Container(
        decoration: BoxDecoration(
            color: p.isActive ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color:
                    p.isActive ? Colors.green.shade300 : Colors.grey.shade300,
                width: 2),
            boxShadow: [
              if (p.isActive)
                BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
            ]),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.restaurant_menu,
                    size: 40, color: p.isActive ? Colors.orange : Colors.grey),
                Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: "Edit",
                        onPressed: () => _showPersonDialog(existingPerson: p)),
                    IconButton(
                        icon:
                            const Icon(Icons.delete_forever, color: Colors.red),
                        tooltip: "Delete",
                        onPressed: () => _deleteStaff(p.id!, p.name))
                  ],
                ),
              ],
            ),
            Text(p.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis),
            Text(p.phone.isNotEmpty ? p.phone : "No Phone",
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: p.isActive
                        ? Colors.green.shade100
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12)),
                child: Text("${p.totalHours} Hour",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: p.isActive
                            ? Colors.green.shade900
                            : Colors.grey.shade700)))
          ],
        ),
      ),
    );
  }
}
