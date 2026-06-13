import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/fitting.dart';
import '../../models/order.dart';
import '../../providers/fitting_provider.dart';
import '../../providers/order_provider.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderListProvider);
    final fittings = ref.watch(allFittingsProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcomingOrders = orders
        .where((o) =>
            o.status != OrderStatus.delivered &&
            o.deliveryDate.isAfter(now.subtract(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));

    final overdueOrders = orders
        .where((o) =>
            o.status != OrderStatus.delivered &&
            o.deliveryDate.isBefore(now))
        .toList()
      ..sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));

    final upcomingFittings = fittings
        .where((f) => !DateTime(f.fittingDate.year, f.fittingDate.month,
                f.fittingDate.day)
            .isBefore(today))
        .toList()
      ..sort((a, b) => a.fittingDate.compareTo(b.fittingDate));

    final isEmpty = orders.isEmpty && fittings.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Takvim')),
      body: isEmpty
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (overdueOrders.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Geciken Siparişler',
                    color: Theme.of(context).colorScheme.error,
                    icon: Icons.warning_amber_outlined,
                  ),
                  const SizedBox(height: 8),
                  ...overdueOrders.map((o) => _CalendarOrderCard(order: o)),
                  const SizedBox(height: 16),
                ],
                if (upcomingFittings.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Yaklaşan Provalar',
                    color: Colors.purple,
                    icon: Icons.content_cut,
                  ),
                  const SizedBox(height: 8),
                  ...upcomingFittings.map((f) => _CalendarFittingCard(fitting: f)),
                  const SizedBox(height: 16),
                ],
                if (upcomingOrders.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Yaklaşan Teslimler',
                    color: Theme.of(context).colorScheme.primary,
                    icon: Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 8),
                  ..._groupByDate(upcomingOrders).entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DateHeader(date: entry.key),
                        ...entry.value.map((o) => _CalendarOrderCard(order: o)),
                        const SizedBox(height: 8),
                      ],
                    );
                  }),
                ],
              ],
            ),
    );
  }

  Map<DateTime, List<Order>> _groupByDate(List<Order> orders) {
    final map = <DateTime, List<Order>>{};
    for (final order in orders) {
      final date = DateTime(
        order.deliveryDate.year,
        order.deliveryDate.month,
        order.deliveryDate.day,
      );
      map.putIfAbsent(date, () => []).add(order);
    }
    return map;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  const _SectionHeader(
      {required this.title, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: color),
        ),
      ],
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    String label;
    if (date == today) {
      label = 'Bugün';
    } else if (date == tomorrow) {
      label = 'Yarın';
    } else {
      label = DateFormat('d MMMM, EEEE', 'tr').format(date);
    }

    final isUrgent = date == today || date == tomorrow;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isUrgent
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

class _CalendarFittingCard extends StatelessWidget {
  final Fitting fitting;
  const _CalendarFittingCard({required this.fitting});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fittingDay = DateTime(
        fitting.fittingDate.year, fitting.fittingDate.month, fitting.fittingDate.day);
    final daysLeft = fittingDay.difference(today).inDays;

    String daysLabel;
    if (daysLeft == 0) {
      daysLabel = 'Bugün!';
    } else if (daysLeft == 1) {
      daysLabel = 'Yarın';
    } else {
      daysLabel = '$daysLeft gün kaldı';
    }

    final isUrgent = daysLeft <= 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fitting.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (fitting.notes != null && fitting.notes!.isNotEmpty)
                    Text(
                      fitting.notes!,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      DateFormat('d MMMM yyyy', 'tr').format(fitting.fittingDate),
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Prova',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.purple,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  daysLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: isUrgent
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.outline,
                    fontWeight:
                        isUrgent ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarOrderCard extends ConsumerWidget {
  final Order order;
  const _CalendarOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final isOverdue = order.deliveryDate.isBefore(now);
    final daysLeft = order.deliveryDate.difference(now).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/orders/${order.id}/edit', extra: order),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: isOverdue
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.productName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.customerName,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadge(status: order.status),
                  const SizedBox(height: 4),
                  Text(
                    isOverdue
                        ? '${daysLeft.abs()} gün geçti'
                        : daysLeft == 0
                            ? 'Bugün!'
                            : '$daysLeft gün kaldı',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOverdue || daysLeft <= 1
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w500),
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
          Icon(Icons.calendar_month_outlined,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('Henüz sipariş veya prova yok',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Siparişler ve provalar buraya yansıyacak',
              style:
                  TextStyle(color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }
}
