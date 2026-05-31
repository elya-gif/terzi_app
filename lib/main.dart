import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/customers/customer_list_screen.dart';
import 'screens/customers/customer_detail_screen.dart';
import 'screens/customers/customer_form_screen.dart';
import 'screens/orders/order_list_screen.dart';
import 'screens/orders/order_form_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'models/customer.dart';
import 'models/order.dart';

void main() {
  runApp(const ProviderScope(child: TerziApp()));
}

final _router = GoRouter(
  initialLocation: '/customers',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/customers',
          builder: (context, state) => const CustomerListScreen(),
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrderListScreen(),
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/customers/:id',
      builder: (context, state) {
        final customer = state.extra as Customer;
        return CustomerDetailScreen(customer: customer);
      },
    ),
    GoRoute(
      path: '/customers/new',
      builder: (context, state) => const CustomerFormScreen(),
    ),
    GoRoute(
      path: '/customers/:id/edit',
      builder: (context, state) {
        final customer = state.extra as Customer;
        return CustomerFormScreen(customer: customer);
      },
    ),
    GoRoute(
      path: '/orders/new',
      builder: (context, state) {
        final customer = state.extra as Customer?;
        return OrderFormScreen(customer: customer);
      },
    ),
    GoRoute(
      path: '/orders/:id/edit',
      builder: (context, state) {
        final order = state.extra as Order;
        return OrderFormScreen(order: order);
      },
    ),
  ],
);

class TerziApp extends StatelessWidget {
  const TerziApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Terzi Yönetim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF185FA5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/calendar')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/customers'); break;
            case 1: context.go('/orders'); break;
            case 2: context.go('/calendar'); break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Müşteriler',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Siparişler',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Takvim',
          ),
        ],
      ),
    );
  }
}
