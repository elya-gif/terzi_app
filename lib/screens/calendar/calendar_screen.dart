import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/fitting.dart';
import '../../models/order.dart';
import '../../providers/fitting_provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/atelier.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderListProvider);
    final fittings = ref.watch(allFittingsProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Yaklaşan: bugün dahil gelecek teslimler (gün bazında)
    final upcomingOrders = orders
        .where((o) {
          if (o.status == OrderStatus.delivered) return false;
          final d = DateTime(o.deliveryDate.year, o.deliveryDate.month, o.deliveryDate.day);
          return !d.isBefore(today);
        })
        .toList()
      ..sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));

    // Geciken: teslim günü geçmiş olanlar (gün bazında)
    final overdueOrders = orders
        .where((o) {
          if (o.status == OrderStatus.delivered) return false;
          final d = DateTime(o.deliveryDate.year, o.deliveryDate.month, o.deliveryDate.day);
          return d.isBefore(today);
        })
        .toList()
      ..sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));

    // Teslim edilmiş siparişlerin orderId'leri
    final deliveredOrderIds = orders
        .where((o) => o.status == OrderStatus.delivered)
        .map((o) => o.id)
        .toSet();

    final upcomingFittings = fittings
        .where((f) {
          // Teslim edilen siparişe ait provaları gösterme
          if (f.orderId != null && deliveredOrderIds.contains(f.orderId)) {
            return false;
          }
          return !DateTime(f.fittingDate.year, f.fittingDate.month,
                  f.fittingDate.day)
              .isBefore(today);
        })
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
                  SectionHeading(
                    label: 'Geciken Siparişler',
                    color: Theme.of(context).colorScheme.error,
                    icon: Icons.warning_amber_outlined,
                  ),
                  ...overdueOrders.map((o) => _CalendarOrderCard(order: o)),
                  const SizedBox(height: 16),
                ],
                if (upcomingFittings.isNotEmpty) ...[
                  SectionHeading(
                    label: 'Yaklaşan Provalar',
                    color: Theme.of(context).extension<AtelierColors>()!.plum,
                    icon: Icons.content_cut,
                  ),
                  ...upcomingFittings.map((f) => _CalendarFittingCard(fitting: f)),
                  const SizedBox(height: 16),
                ],
                if (upcomingOrders.isNotEmpty) ...[
                  SectionHeading(
                    label: 'Yaklaşan Teslimler',
                    color: Theme.of(context).extension<AtelierColors>()!.brass,
                    icon: Icons.calendar_today_outlined,
                  ),
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

class _CalendarFittingCard extends ConsumerWidget {
  final Fitting fitting;
  const _CalendarFittingCard({required this.fitting});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final plum = Theme.of(context).extension<AtelierColors>()!.plum;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () => _confirmDelete(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SeamAccent(color: plum, height: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fitting.customerName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (fitting.productName != null)
                      Text(
                        fitting.productName!,
                        style: TextStyle(
                            fontSize: 12,
                            color: plum,
                            fontWeight: FontWeight.w600),
                      ),
                    if (fitting.notes != null && fitting.notes!.isNotEmpty)
                      Text(
                        fitting.notes!,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline),
                      )
                    else
                      Text(
                        DateFormat('d MMMM yyyy, EEEE', 'tr').format(fitting.fittingDate),
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
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: plum.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      'PROVA',
                      style: TextStyle(
                          fontSize: 10,
                          color: plum,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5),
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
                      fontWeight: isUrgent ? FontWeight.w600 : FontWeight.normal,
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Provayı sil'),
        content: Text('${fitting.customerName} müşterisinin provasını silmek istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(fittingProvider(fitting.customerId).notifier)
          .deleteFitting(fitting.id!);
    }
  }
}

class _CalendarOrderCard extends ConsumerWidget {
  final Order order;
  const _CalendarOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final atelier = Theme.of(context).extension<AtelierColors>()!;
    final isOverdue = order.deliveryDate.isBefore(now);
    final daysLeft = order.deliveryDate.difference(now).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/orders/${order.id}/edit', extra: order),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              SeamAccent(
                color: isOverdue
                    ? Theme.of(context).colorScheme.error
                    : atelier.brass,
              ),
              const SizedBox(width: 14),
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
                mainAxisAlignment: MainAxisAlignment.center,
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
    ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final atelier = Theme.of(context).extension<AtelierColors>()!;
    final color =
        status == OrderStatus.delivered ? atelier.sage : atelier.brass;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2),
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
