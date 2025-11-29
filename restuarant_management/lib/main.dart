import 'package:flutter/material.dart';
import 'person.dart';
import 'login_page.dart';
import 'manager_dashboard.dart';
import 'orders_page.dart';
import 'waiters_page.dart';
import 'kitchen_page.dart';
import 'kitchen_home.dart';
import 'menu_page.dart';
import 'waiter_home.dart';
import 'tables_page.dart';

void main() {
  runApp(const RestaurantApp());
}

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant System',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(scrollbars: true),
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),

        // --- MANAGER PAGES ---
        '/dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Person) return DashboardHome(currentUser: args);
          return const LoginPage();
        },

        '/orders': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Person) return OrdersPage(currentUser: args);
          return const LoginPage();
        },

        '/waiters': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Person) return WaitersPage(currentUser: args);
          return const LoginPage();
        },

        '/manage_tables': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Person) return TablesPage(currentUser: args);
          return const LoginPage();
        },

        '/kitchen_list': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Person) return KitchenPage(currentUser: args);
          return const LoginPage();
        },

        '/menu': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Person) return MenuPage(currentUser: args);
          return const LoginPage();
        },

        // --- EMPLOYEE SCREEN ---
        '/waiter_home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Person) return WaiterHome(currentWaiter: args);
          return const LoginPage();
        },

        '/kitchen_home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Person) return KitchenHome(currentChef: args);
          return const LoginPage();
        },
      },
    );
  }
}
