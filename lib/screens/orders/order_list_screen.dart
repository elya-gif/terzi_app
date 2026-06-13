import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../providers/fitting_provider.dart';
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
                        _SwipeableOrderCard(order: filtered[index]),
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

class _SwipeableOrderCard extends ConsumerWidget {
  final Order order;
  const _SwipeableOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDelivered = order.status == OrderStatus.delivered;

    if (isDelivered) {
      return _OrderCardContent(order: order);
    }

    return Dismissible(
      key: ValueKey('order_${order.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await ref
            .read(orderListProvider.notifier)
            .updateStatus(order, OrderStatus.delivered);
        return false; // liste item'ı kaldırma, sadece güncelle
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Teslim Edildi',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: _OrderCardContent(order: order),
    );
  }
}

class _OrderCardContent extends ConsumerWidget {
  final Order order;
  const _OrderCardContent({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('d MMM yyyy', 'tr');
    final isDelivered = order.status == OrderStatus.delivered;
    final daysLeft = order.deliveryDate.difference(DateTime.now()).inDays;
    final isUrgent = !isDelivered && daysLeft <= 2;

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
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: isDelivered
                              ? Theme.of(context).colorScheme.outline
                              : null),
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
                  Icon(Icons.calendar_today_outlined,
                      size: 14,
                      color: isUrgent ? Colors.red : null),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(order.deliveryDate),
                    style: TextStyle(
                        fontSize: 12,
                        color: isUrgent
                            ? Colors.red
                            : Theme.of(context).colorScheme.outline,
                        fontWeight:
                            isUrgent ? FontWeight.w600 : FontWeight.normal),
                  ),
                  if (isUrgent) ...[
                    const SizedBox(width: 4),
                    Text(
                      daysLeft == 0
                          ? '(Bugün!)'
                          : daysLeft < 0
                              ? '(${-daysLeft} gün geçti!)'
                              : '($daysLeft gün kaldı)',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '₺${order.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                ],
              ),
              if (!isDelivered) ...[
                const SizedBox(height: 6),
                _FittingRow(customerId: order.customerId),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.swipe_left_outlined,
                          size: 14,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(
                        'Teslim için sola kaydır',
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == OrderStatus.delivered
        ? Colors.grey
        : Theme.of(context).colorScheme.primary;
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
}

class _FittingRow extends ConsumerWidget {
  final int customerId;
  const _FittingRow({required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fitting = ref.watch(nextFittingProvider(customerId));
    if (fitting == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fittingDay = DateTime(
        fitting.fittingDate.year, fitting.fittingDate.month, fitting.fittingDate.day);
    final daysLeft = fittingDay.difference(today).inDays;

    String label;
    if (daysLeft == 0) {
      label = 'Prova bugün!';
    } else if (daysLeft == 1) {
      label = 'Prova yarın';
    } else {
      label = 'Provaya $daysLeft gün kaldı';
    }

    return Row(
      children: [
        Icon(Icons.content_cut, size: 13, color: Colors.purple.shade400),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: daysLeft <= 1 ? Colors.purple.shade700 : Colors.purple.shade400,
            fontWeight: daysLeft <= 1 ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
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
          Icon(Icons.list_alt_outlined,
              size: 64, color: Theme.of(context).colorScheme.outline),
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
