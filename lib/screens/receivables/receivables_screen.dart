import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../models/payment_record.dart';
import '../../providers/order_provider.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/alpha_scroll_list.dart';
import '../../widgets/atelier.dart';
import '../../theme/app_theme.dart';

// Müşteri başına borç özeti
class CustomerDebt {
  final int customerId;
  final String customerName;
  final List<Order> orders;
  double get totalDebt =>
      orders.fold(0, (sum, o) => sum + o.remainingDebt);

  CustomerDebt({
    required this.customerId,
    required this.customerName,
    required this.orders,
  });
}

// ─── Ana alacaklar ekranı (müşteri listesi) ───────────────────────────────────

class ReceivablesScreen extends ConsumerStatefulWidget {
  const ReceivablesScreen({super.key});

  @override
  ConsumerState<ReceivablesScreen> createState() => _ReceivablesScreenState();
}

class _ReceivablesScreenState extends ConsumerState<ReceivablesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(orderListProvider);

    // Teslim edilmiş ama hâlâ borcu olan siparişleri müşteri bazında grupla
    final Map<int, CustomerDebt> byCustomer = {};
    for (final o in orders) {
      if (o.status == OrderStatus.delivered && o.remainingDebt > 0) {
        byCustomer.putIfAbsent(
          o.customerId,
          () => CustomerDebt(
            customerId: o.customerId,
            customerName: o.customerName,
            orders: [],
          ),
        ).orders.add(o);
      }
    }

    // Alfabetik sırala
    var customers = byCustomer.values.toList()
      ..sort((a, b) => a.customerName.compareTo(b.customerName));

    if (_query.isNotEmpty) {
      customers = customers
          .where((c) =>
              c.customerName.toLowerCase().contains(_query.toLowerCase()))
          .toList();
    }

    final totalDebt = customers.fold<double>(0, (s, c) => s + c.totalDebt);

    return Scaffold(
      appBar: AppBar(title: const Text('Alacaklar')),
      body: customers.isEmpty && _query.isEmpty
          ? const _EmptyState()
          : Column(
              children: [
                _TotalBanner(total: totalDebt),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Müşteri ara...',
                    leading: const Icon(Icons.search, size: 20),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: customers.isEmpty
                      ? const Center(child: Text('Sonuç bulunamadı'))
                      : AlphaScrollList<CustomerDebt>(
                          items: customers,
                          labelOf: (c) => c.customerName,
                          itemBuilder: (context, c) =>
                              CustomerDebtCard(debt: c),
                        ),
                ),
              ],
            ),
    );
  }
}

class _TotalBanner extends StatelessWidget {
  final double total;
  const _TotalBanner({required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SeamAccent(color: scheme.error, height: 44),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOPLAM ALACAK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: Theme.of(context)
                          .extension<AtelierColors>()!
                          .graphite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₺${total.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: scheme.error,
                          fontSize: 34,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.account_balance_wallet_outlined,
                size: 28, color: scheme.error.withValues(alpha: 0.55)),
          ],
        ),
      ),
    );
  }
}

class CustomerDebtCard extends StatelessWidget {
  final CustomerDebt debt;
  const CustomerDebtCard({super.key, required this.debt});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final atelier = Theme.of(context).extension<AtelierColors>()!;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerReceivablesScreen(debt: debt),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
          child: Row(
            children: [
              MonogramAvatar(
                name: debt.customerName,
                color: scheme.error,
                background: scheme.errorContainer,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(debt.customerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text('${debt.orders.length} borçlu sipariş',
                        style:
                            TextStyle(fontSize: 13, color: atelier.graphite)),
                  ],
                ),
              ),
              Text(
                '₺${debt.totalDebt.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      color: scheme.error,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Müşteri alacak detay ekranı ─────────────────────────────────────────────

class CustomerReceivablesScreen extends ConsumerWidget {
  final CustomerDebt debt;
  const CustomerReceivablesScreen({super.key, required this.debt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Güncel order listesinden bu müşterinin borçlu siparişlerini al
    final allOrders = ref.watch(orderListProvider);
    final orders = allOrders
        .where((o) =>
            o.customerId == debt.customerId &&
            o.status == OrderStatus.delivered &&
            o.remainingDebt > 0)
        .toList()
      ..sort((a, b) => b.deliveryDate.compareTo(a.deliveryDate));

    final totalDebt = orders.fold<double>(0, (s, o) => s + o.remainingDebt);

    return Scaffold(
      appBar: AppBar(
        title: Text(debt.customerName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 6),
                Text(
                  'Toplam alacak: ₺${totalDebt.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: orders.isEmpty
          ? Center(
              child: Text('Alacak kalmadı',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.outline)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  _OrderDebtCard(order: orders[i]),
            ),
    );
  }
}

// ─── Tek sipariş borç kartı (ödeme geçmişiyle) ───────────────────────────────

class _OrderDebtCard extends ConsumerWidget {
  final Order order;
  const _OrderDebtCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(paymentProvider(order.id!));
    final dateFormat = DateFormat('d MMMM yyyy', 'tr');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sipariş başlığı
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.productName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        'Teslim: ${dateFormat.format(order.deliveryDate)}',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline),
                      ),
                      Text(
                        'Toplam: ₺${order.price.toStringAsFixed(0)}'
                        '  •  Ödendi: ₺${order.paidAmount.toStringAsFixed(0)}',
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
                    Text(
                      '₺${order.remainingDebt.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 22,
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                    Text('kalan',
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.outline)),
                  ],
                ),
              ],
            ),

            // Ödeme geçmişi
            if (payments.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Text('Ödeme Geçmişi',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.outline)),
              const SizedBox(height: 6),
              ...payments.map((p) => _PaymentRow(payment: p)),
            ],

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => _showPaymentDialog(context, ref),
                child: const Text('Ödeme Al'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPaymentDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: order.remainingDebt.toStringAsFixed(0),
    );
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ödeme Al'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.productName,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
              'Kalan borç: ₺${order.remainingDebt.toStringAsFixed(0)}',
              style: TextStyle(
                  color: Theme.of(ctx).colorScheme.error,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Alınan tutar',
                prefixText: '₺',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim()) ?? 0;
              Navigator.pop(ctx, v.clamp(0, order.remainingDebt).toDouble());
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (amount != null && amount > 0) {
      await ref.read(orderListProvider.notifier).addPaymentToOrder(order, amount);
      // Ödeme provider'ını yenile
      ref.read(paymentProvider(order.id!).notifier).reload();
    }
  }
}

class _PaymentRow extends StatelessWidget {
  final PaymentRecord payment;
  const _PaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy, HH:mm', 'tr');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline,
              size: 14,
              color: Theme.of(context).extension<AtelierColors>()!.sage),
          const SizedBox(width: 6),
          Text(
            dateFormat.format(payment.paidAt),
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline),
          ),
          const Spacer(),
          Text(
            '₺${payment.amount.toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
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
          Icon(Icons.check_circle_outline,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('Alacak yok',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Tüm ödemeler alınmış',
              style:
                  TextStyle(color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }
}
