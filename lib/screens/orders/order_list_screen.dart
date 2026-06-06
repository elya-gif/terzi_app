import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';

final selectedStatusProvider = StateProvider<OrderStatus?>((ref) => null);

class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderListProvider);
    final selectedStatus = ref.watch(selectedStatusProvider);

    final filtered = selectedStatus == null
        ? orders
        : orders.where((o) => o.status == selectedStatus).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Siparişler'),
      ),
      body: Column(
        children: [
          _StatusFilter(),
          Expanded(
            child: filtered.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _OrderCard(order: filtered[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/orders/new'),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Sipariş'),
      ),
    );
  }
}

class _StatusFilter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedStatusProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _FilterChip(
            label: 'Tümü',
            selected: selected == null,
            onTap: () => ref.read(selectedStatusProvider.notifier).state = null,
          ),
          const SizedBox(width: 8),
          ...OrderStatus.values.map((status) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: status.label,
                  selected: selected == status,
                  onTap: () =>
                      ref.read(selectedStatusProvider.notifier).state = status,
                ),
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('d MMM yyyy', 'tr');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/orders/${order.id}/edit', extra: order),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.productName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 15),
                    ),
                  ),
                  _StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14),
                  const SizedBox(width: 4),
                  Text(order.customerName,
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.outline)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(order.deliveryDate),
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline),
                  ),
                  const Spacer(),
                  Text(
                    '₺${order.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _StatusStepper(order: order),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusStepper extends ConsumerWidget {
  final Order order;
  const _StatusStepper({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = OrderStatus.values;
    final currentIndex = statuses.indexOf(order.status);

    return Row(
      children: statuses.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isCompleted = index <= currentIndex;
        final isLast = index == statuses.length - 1;

        return Expanded(
          child: Row(
            children: [
              GestureDetector(
                onTap: () => ref
                    .read(orderListProvider.notifier)
                    .updateStatus(order, status),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: isCompleted
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      width: 1.5,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 1.5,
                    color: isCompleted && index < currentIndex
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Color _color(BuildContext context) {
    switch (status) {
      case OrderStatus.inProgress: return Colors.orange;
      case OrderStatus.ready:      return Colors.green;
      case OrderStatus.delivered:  return Colors.grey;
      default: return Theme.of(context).colorScheme.primary;
    }
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
          Icon(Icons.list_alt_outlined, size: 64,
              color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('Henüz sipariş yok',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Aşağıdaki butona bas',
              style: TextStyle(color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }
}