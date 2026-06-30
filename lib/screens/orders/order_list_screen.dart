import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../providers/fitting_provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/atelier.dart';

final selectedStatusProvider = StateProvider<OrderStatus?>((ref) => null);
final orderSearchQueryProvider = StateProvider<String>((ref) => '');

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(orderListProvider);
    final selectedStatus = ref.watch(selectedStatusProvider);
    final query = ref.watch(orderSearchQueryProvider);

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    // Yarın teslim edilecek aktif siparişler (filtre/arama bağımsız, her zaman göster)
    final tomorrowOrders = orders.where((o) {
      if (o.status == OrderStatus.delivered) return false;
      final d = DateTime(o.deliveryDate.year, o.deliveryDate.month, o.deliveryDate.day);
      return d == tomorrow;
    }).toList();

    // Teslim edildi filtresi seçiliyse tüm teslim edilenleri göster,
    // aksi halde sadece aktif siparişleri göster
    var filtered = selectedStatus == OrderStatus.delivered
        ? orders.where((o) => o.status == OrderStatus.delivered).toList()
        : orders.where((o) => o.status != OrderStatus.delivered).toList();

    if (selectedStatus != null && selectedStatus != OrderStatus.delivered) {
      filtered = filtered.where((o) => o.status == selectedStatus).toList();
    }

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      filtered = filtered
          .where((o) =>
              o.productName.toLowerCase().contains(q) ||
              o.customerName.toLowerCase().contains(q))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Siparişler'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Sipariş veya müşteri ara...',
              leading: const Icon(Icons.search, size: 20),
              onChanged: (v) =>
                  ref.read(orderSearchQueryProvider.notifier).state = v,
            ),
          ),
          _StatusFilter(),
          Expanded(
            child: filtered.isEmpty && tomorrowOrders.isEmpty
                ? const _EmptyState()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Yarın teslim bölümü (arama yoksa ve teslim edildi filtresi seçili değilse göster)
                      if (tomorrowOrders.isNotEmpty && query.isEmpty && selectedStatus != OrderStatus.delivered) ...[
                        SectionHeading(
                          label: 'Yarın Teslim',
                          icon: Icons.schedule,
                          color: Theme.of(context)
                              .extension<AtelierColors>()!
                              .amber,
                        ),
                        ...tomorrowOrders.map((o) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _SwipeableOrderCard(order: o),
                            )),
                        const SizedBox(height: 16),
                      ],
                      ...filtered.map((o) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _SwipeableOrderCard(order: o),
                          )),
                    ],
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
            label: 'Hepsi',
            selected: selected == null,
            onTap: () => ref.read(selectedStatusProvider.notifier).state = null,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Teslim Edildi',
            selected: selected == OrderStatus.delivered,
            onTap: () => ref.read(selectedStatusProvider.notifier).state =
                OrderStatus.delivered,
          ),
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
          color: Theme.of(context).extension<AtelierColors>()!.sage,
          borderRadius: BorderRadius.circular(16),
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
    final atelier = Theme.of(context).extension<AtelierColors>()!;
    final isDelivered = order.status == OrderStatus.delivered;
    final daysLeft = order.deliveryDate.difference(DateTime.now()).inDays;
    final isUrgent = !isDelivered && daysLeft <= 2;

    final accent = isDelivered
        ? atelier.graphite
        : isUrgent
            ? atelier.amber
            : atelier.brass;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isDelivered
            ? null
            : () => context.push('/orders/${order.id}/edit', extra: order),
        onLongPress: isDelivered ? () => _confirmDelete(context, ref) : null,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: SeamAccent(color: accent),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.productName,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: isDelivered ? atelier.graphite : null),
                            ),
                          ),
                          _StatusBadge(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 14, color: atelier.graphite),
                          const SizedBox(width: 4),
                          Text(order.customerName,
                              style: TextStyle(
                                  fontSize: 13, color: atelier.graphite)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 14,
                              color: isUrgent ? atelier.amber : atelier.graphite),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(order.deliveryDate),
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    isUrgent ? atelier.amber : atelier.graphite,
                                fontWeight: isUrgent
                                    ? FontWeight.w700
                                    : FontWeight.normal),
                          ),
                          if (isUrgent) ...[
                            const SizedBox(width: 4),
                            Text(
                              daysLeft == 0
                                  ? '· Bugün!'
                                  : daysLeft < 0
                                      ? '· ${-daysLeft} gün geçti'
                                      : '· $daysLeft gün kaldı',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: atelier.amber,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            '₺${order.price.toStringAsFixed(0)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontSize: 19,
                                  color: isDelivered ? atelier.graphite : null,
                                ),
                          ),
                        ],
                      ),
                      if (!isDelivered) ...[
                        const SizedBox(height: 8),
                        _FittingRow(customerId: order.customerId),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.swipe_left_outlined,
                                  size: 14, color: atelier.graphite),
                              const SizedBox(width: 4),
                              Text(
                                'Teslim için sola kaydır',
                                style: TextStyle(
                                    fontSize: 11, color: atelier.graphite),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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
        title: const Text('Siparişi sil'),
        content: Text('"${order.productName}" siparişini silmek istediğine emin misin?'),
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
      await ref.read(orderListProvider.notifier).deleteOrder(order.id!);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final atelier = Theme.of(context).extension<AtelierColors>()!;
    final color = status == OrderStatus.delivered ? atelier.sage : atelier.brass;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2),
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

    final plum = Theme.of(context).extension<AtelierColors>()!.plum;
    return Row(
      children: [
        Icon(Icons.content_cut, size: 13, color: plum),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: plum,
            fontWeight: daysLeft <= 1 ? FontWeight.w700 : FontWeight.w500,
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
