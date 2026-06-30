import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import '../../providers/customer_provider.dart';
import '../../models/customer.dart';
import '../../widgets/alpha_scroll_list.dart';
import '../../widgets/atelier.dart';
import '../../theme/app_theme.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredCustomersProvider = Provider<List<Customer>>((ref) {
  final customers = ref.watch(customerListProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  if (query.isEmpty) return customers;
  return customers.where((c) =>
    c.name.toLowerCase().contains(query) ||
    c.phone.contains(query)
  ).toList();
});

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşteriler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => context.push('/customers/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              hintText: 'Müşteri ara...',
              leading: const Icon(Icons.search, size: 20),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
          ),
          Expanded(
            child: customers.isEmpty
                ? const _EmptyState()
                : _CustomerList(customers: customers),
          ),
        ],
      ),
    );
  }
}

class _CustomerList extends ConsumerWidget {
  final List<Customer> customers;
  const _CustomerList({required this.customers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = ref.watch(filteredCustomersProvider);

    if (filtered.isEmpty) {
      return Center(
        child: Text('Sonuç bulunamadı',
            style: TextStyle(
                color: Theme.of(context).extension<AtelierColors>()!.graphite)),
      );
    }

    return AlphaScrollList<Customer>(
      items: filtered,
      labelOf: (c) => c.name,
      itemBuilder: (context, customer) => _CustomerCard(customer: customer),
    );
  }
}

class _CustomerCard extends ConsumerWidget {
  final Customer customer;
  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderCountProvider(customer.id!));
    final atelier = Theme.of(context).extension<AtelierColors>()!;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            context.push('/customers/${customer.id}', extra: customer),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
          child: Row(
            children: [
              MonogramAvatar(name: customer.name),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.phone,
                      style: TextStyle(
                        fontSize: 13,
                        color: atelier.graphite,
                      ),
                    ),
                  ],
                ),
              ),
              if (orders > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: atelier.brassSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$orders sipariş',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: atelier.brass,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64,
              color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('Henüz müşteri yok',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Sağ üstteki + ile ekleyebilirsin',
              style: TextStyle(color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }
}
