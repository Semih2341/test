import 'package:flutter/material.dart';
import 'api_service.dart';
import 'person.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    String u = _userCtrl.text.trim();
    String p = _passCtrl.text.trim();

    if (u.isEmpty || p.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Please enter information.";
      });
      return;
    }

    Person? user = await _apiService.login(u, p);

    if (user != null) {
      await _apiService.startShift(user);
      if (!mounted) return;

      if (user.role == "Manager") {
        Navigator.pushReplacementNamed(context, '/dashboard', arguments: user);
      } else if (user.role == "Waiter") {
        Navigator.pushReplacementNamed(context, '/waiter_home',
            arguments: user);
      } else if (user.role == "Kitchen") {
        Navigator.pushReplacementNamed(context, '/kitchen_home',
            arguments: user);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "Undefined Role!";
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "Invalid Input!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.restaurant_menu,
                    size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text("Log In",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(
                        labelText: "User Name", border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: "Password", border: OutlineInputBorder())),
                if (_errorMessage != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red))),
                const SizedBox(height: 24),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16)),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text("Login")))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
