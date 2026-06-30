import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customers/customer_list_screen.dart';
import 'screens/customers/customer_detail_screen.dart';
import 'screens/customers/customer_form_screen.dart';
import 'screens/orders/order_list_screen.dart';
import 'screens/orders/order_form_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/receivables/receivables_screen.dart';
import 'models/customer.dart';
import 'models/order.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await initializeDateFormatting('tr', null);
  runApp(const ProviderScope(child: TerziApp()));
  // Bildirim kurulumu UI'yı bloklamaz; arka planda kurulur.
  unawaited(NotificationService.instance.init());
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/customers',
    refreshListenable: _GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
    redirect: (context, state) {
      final loggedIn = FirebaseAuth.instance.currentUser != null;
      final goingToLogin = state.matchedLocation == '/login';
      if (!loggedIn && !goingToLogin) return '/login';
      if (loggedIn && goingToLogin) return '/customers';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
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
          GoRoute(
            path: '/receivables',
            builder: (context, state) => const ReceivablesScreen(),
          ),
        ],
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
        path: '/customers/:id',
        builder: (context, state) {
          final customer = state.extra as Customer;
          return CustomerDetailScreen(customer: customer);
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
});

class TerziApp extends ConsumerWidget {
  const TerziApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Terzi Yönetim',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr'), Locale('en')],
      locale: const Locale('tr'),
      theme: buildAtelierTheme(),
      routerConfig: ref.watch(routerProvider),
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
    if (location.startsWith('/receivables')) return 3;
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
            case 0:
              context.go('/customers');
              break;
            case 1:
              context.go('/orders');
              break;
            case 2:
              context.go('/calendar');
              break;
            case 3:
              context.go('/receivables');
              break;
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
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Alacaklar',
          ),
        ],
      ),
    );
  }
}
