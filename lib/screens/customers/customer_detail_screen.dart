import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../models/fitting.dart';
import '../../models/measurement.dart';
import '../../models/order.dart';
import '../../providers/fitting_provider.dart';
import '../../providers/measurement_provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_theme.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final Customer customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push('/customers/${customer.id}/edit', extra: customer),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: Theme.of(context).extension<AtelierColors>()!.brass,
          unselectedLabelColor:
              Theme.of(context).extension<AtelierColors>()!.graphite,
          indicatorColor: Theme.of(context).extension<AtelierColors>()!.brass,
          indicatorWeight: 2.5,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'Ölçüler'),
            Tab(text: 'Siparişler'),
            Tab(text: 'Provalar'),
            Tab(text: 'Notlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MeasurementsTab(customer: customer),
          _OrdersTab(customer: customer),
          _FittingsTab(customer: customer),
          _NotesTab(customer: customer),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildFab(BuildContext context) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        if (_tabController.index == 0) {
          return FloatingActionButton.extended(
            onPressed: () => _showMeasurementForm(context),
            icon: const Icon(Icons.straighten),
            label: const Text('Ölçü Ekle'),
          );
        } else if (_tabController.index == 1) {
          return FloatingActionButton.extended(
            onPressed: () =>
                context.push('/orders/new', extra: widget.customer),
            icon: const Icon(Icons.add),
            label: const Text('Sipariş Ekle'),
          );
        } else if (_tabController.index == 2) {
          return FloatingActionButton.extended(
            onPressed: () => _showFittingForm(context),
            icon: const Icon(Icons.content_cut),
            label: const Text('Prova Ekle'),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showFittingForm(BuildContext context) {
    final allOrders = ref.read(orderListProvider);
    // Sadece teslim edilmemiş siparişleri göster
    final orders = allOrders
        .where((o) =>
            o.customerId == widget.customer.id &&
            o.status != OrderStatus.delivered)
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          FittingFormSheet(customer: widget.customer, orders: orders),
    );
  }

  void _showMeasurementForm(BuildContext context,
      {Measurement? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MeasurementFormSheet(
        customerId: widget.customer.id!,
        existing: existing,
      ),
    );
  }
}

// ─── Ölçüler sekmesi ─────────────────────────────────────────────────────────

class _MeasurementsTab extends ConsumerWidget {
  final Customer customer;
  const _MeasurementsTab({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurements = ref.watch(measurementProvider(customer.id!));

    if (measurements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.straighten,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            const Text('Henüz ölçü yok'),
            const SizedBox(height: 8),
            Text(
              'Aşağıdaki butona bas',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: measurements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _MeasurementCard(
        measurement: measurements[index],
        onEdit: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => MeasurementFormSheet(
              customerId: measurements[index].customerId,
              existing: measurements[index],
            ),
          );
        },
      ),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final Measurement measurement;
  final VoidCallback onEdit;
  const _MeasurementCard({required this.measurement, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final date =
        DateFormat('d MMMM yyyy', 'tr').format(measurement.createdAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14),
                const SizedBox(width: 6),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (measurement.chest != null)
                  _MeasureChip(label: 'Göğüs', value: measurement.chest!),
                if (measurement.waist != null)
                  _MeasureChip(label: 'Bel', value: measurement.waist!),
                if (measurement.hips != null)
                  _MeasureChip(label: 'Kalça', value: measurement.hips!),
                if (measurement.upperHeight != null)
                  _MeasureChip(
                      label: 'Üst boy', value: measurement.upperHeight!),
                if (measurement.lowerHeight != null)
                  _MeasureChip(
                      label: 'Alt boy', value: measurement.lowerHeight!),
                if (measurement.armLength != null)
                  _MeasureChip(
                      label: 'Kol boy', value: measurement.armLength!),
                if (measurement.skirtLength != null)
                  _MeasureChip(
                      label: 'Etek boy', value: measurement.skirtLength!),
                if (measurement.pantLength != null)
                  _MeasureChip(
                      label: 'Pant boy', value: measurement.pantLength!),
                if (measurement.vestLength != null)
                  _MeasureChip(
                      label: 'Yelek boy', value: measurement.vestLength!),
                if (measurement.jacketLength != null)
                  _MeasureChip(
                      label: 'Çeket boy', value: measurement.jacketLength!),
                if (measurement.tunicLength != null)
                  _MeasureChip(
                      label: 'Tunik boy', value: measurement.tunicLength!),
                if (measurement.upperBodyLength != null)
                  _MeasureChip(
                      label: 'Üst beden', value: measurement.upperBodyLength!),
                if (measurement.shortLength != null)
                  _MeasureChip(
                      label: 'Şort boy', value: measurement.shortLength!),
              ],
            ),
            if (measurement.notes != null &&
                measurement.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                measurement.notes!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MeasureChip extends StatelessWidget {
  final String label;
  final double value;
  const _MeasureChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)} cm',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Siparişler sekmesi (aktif + teslim edilenler ayrı) ──────────────────────

class _OrdersTab extends ConsumerWidget {
  final Customer customer;
  const _OrdersTab({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allOrders = ref.watch(orderListProvider);
    final orders = allOrders
        .where((o) => o.customerId == customer.id)
        .toList()
      ..sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt_outlined, size: 56,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            const Text('Henüz sipariş yok'),
          ],
        ),
      );
    }

    final active = orders.where((o) => o.status != OrderStatus.delivered).toList();
    final delivered = orders.where((o) => o.status == OrderStatus.delivered).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (active.isNotEmpty) ...[
          ...active.map((o) => _CustomerOrderCard(order: o, isDelivered: false)),
        ],
        if (delivered.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 14,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(width: 6),
                Text('Teslim Edilenler',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.outline,
                    )),
              ],
            ),
          ),
          ...delivered.map((o) => _CustomerOrderCard(order: o, isDelivered: true)),
        ],
      ],
    );
  }
}

class _CustomerOrderCard extends ConsumerWidget {
  final Order order;
  final bool isDelivered;
  const _CustomerOrderCard({required this.order, required this.isDelivered});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isDelivered
              ? null
              : () => context.push('/orders/${order.id}/edit', extra: order),
          onLongPress: isDelivered ? () => _confirmDelete(context, ref) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: isDelivered
                              ? Theme.of(context).colorScheme.outline
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d MMM yyyy', 'tr').format(order.deliveryDate),
                        style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₺${order.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    _StatusBadge(status: order.status),
                  ],
                ),
              ],
            ),
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

// ─── Provalar sekmesi (ürün bazlı, sadece aktif siparişler) ──────────────────

class _FittingsTab extends ConsumerWidget {
  final Customer customer;
  const _FittingsTab({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fittings = ref.watch(fittingProvider(customer.id!));
    final allOrders = ref.watch(orderListProvider);
    final dateFormat = DateFormat('d MMMM yyyy', 'tr');

    // Teslim edilmiş siparişlerin orderId'lerini bul
    final deliveredOrderIds = allOrders
        .where((o) =>
            o.customerId == customer.id &&
            o.status == OrderStatus.delivered)
        .map((o) => o.id)
        .toSet();

    // Teslim edilen siparişlere ait provaları filtrele
    final activeFittings = fittings
        .where((f) => f.orderId == null || !deliveredOrderIds.contains(f.orderId))
        .toList();

    if (activeFittings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.content_cut,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            const Text('Henüz prova yok'),
            const SizedBox(height: 8),
            Text(
              'Aşağıdaki butona bas',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: activeFittings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final fitting = activeFittings[index];
        final isPast = fitting.fittingDate.isBefore(DateTime.now());
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPast
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.content_cut,
                size: 20,
                color: isPast
                    ? Theme.of(context).colorScheme.outline
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              dateFormat.format(fitting.fittingDate),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (fitting.productName != null && fitting.productName!.isNotEmpty)
                  Text(fitting.productName!,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500)),
                if (fitting.notes != null && fitting.notes!.isNotEmpty)
                  Text(fitting.notes!,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isPast ? 'Geçti' : _daysUntil(fitting.fittingDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: isPast
                        ? Theme.of(context).colorScheme.outline
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: isPast ? FontWeight.normal : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => _showEditForm(context, ref, fitting),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            onLongPress: () => _confirmDelete(context, ref, fitting),
          ),
        );
      },
    );
  }

  String _daysUntil(DateTime date) {
    final diff = date.difference(DateTime.now()).inDays;
    if (diff == 0) return 'Bugün';
    if (diff == 1) return 'Yarın';
    return '$diff gün sonra';
  }

  Future<void> _showEditForm(
    BuildContext context,
    WidgetRef ref,
    Fitting fitting,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FittingEditSheet(
        fitting: fitting,
        customerId: customer.id!,
        ref: ref,
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Fitting fitting,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Provayı sil'),
        content: const Text('Bu provayı silmek istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(fittingProvider(customer.id!).notifier)
          .deleteFitting(fitting.id!);
    }
  }
}

// ─── Prova düzenleme formu ────────────────────────────────────────────────────

class _FittingEditSheet extends StatefulWidget {
  final Fitting fitting;
  final int customerId;
  final WidgetRef ref;
  const _FittingEditSheet({
    required this.fitting,
    required this.customerId,
    required this.ref,
  });

  @override
  State<_FittingEditSheet> createState() => _FittingEditSheetState();
}

class _FittingEditSheetState extends State<_FittingEditSheet> {
  late DateTime _fittingDate;
  late TextEditingController _notesController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fittingDate = widget.fitting.fittingDate;
    _notesController = TextEditingController(text: widget.fitting.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fittingDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('tr'),
    );
    if (picked != null) setState(() => _fittingDate = picked);
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final updated = widget.fitting.copyWith(
      fittingDate: _fittingDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    await widget.ref
        .read(fittingProvider(widget.customerId).notifier)
        .updateFitting(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMMM yyyy', 'tr');
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Provayı Düzenle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Prova Tarihi'),
            subtitle: Text(dateFormat.format(_fittingDate),
                style: const TextStyle(fontWeight: FontWeight.w500)),
            trailing: const Icon(Icons.chevron_right),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: Theme.of(context).colorScheme.outline, width: 0.5),
            ),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Not (opsiyonel)',
              prefixIcon: const Icon(Icons.note_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Güncelle'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notlar sekmesi ───────────────────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  final Customer customer;
  const _NotesTab({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: customer.notes == null || customer.notes!.isEmpty
          ? Center(
              child: Text(
                'Not yok',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            )
          : Text(customer.notes!, style: const TextStyle(fontSize: 15)),
    );
  }
}

// ─── Durum rozeti ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _color(BuildContext context) {
    final atelier = Theme.of(context).extension<AtelierColors>()!;
    switch (status) {
      case OrderStatus.delivered:
        return atelier.sage;
      default:
        return atelier.brass;
    }
  }
}

// ─── Ölçü formu (ekle / düzenle) ─────────────────────────────────────────────

class MeasurementFormSheet extends ConsumerStatefulWidget {
  final int customerId;
  final Measurement? existing;
  const MeasurementFormSheet({
    super.key,
    required this.customerId,
    this.existing,
  });

  @override
  ConsumerState<MeasurementFormSheet> createState() =>
      _MeasurementFormSheetState();
}

class _MeasurementFormSheetState
    extends ConsumerState<MeasurementFormSheet> {
  late final Map<String, TextEditingController> _controllers;
  late final TextEditingController _notesController;
  bool _isLoading = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _controllers = {
      'chest': TextEditingController(
          text: e?.chest?.toStringAsFixed(1) ?? ''),
      'waist': TextEditingController(
          text: e?.waist?.toStringAsFixed(1) ?? ''),
      'hips': TextEditingController(
          text: e?.hips?.toStringAsFixed(1) ?? ''),
      'upperHeight': TextEditingController(
          text: e?.upperHeight?.toStringAsFixed(1) ?? ''),
      'lowerHeight': TextEditingController(
          text: e?.lowerHeight?.toStringAsFixed(1) ?? ''),
      'armLength': TextEditingController(
          text: e?.armLength?.toStringAsFixed(1) ?? ''),
      'skirtLength': TextEditingController(
          text: e?.skirtLength?.toStringAsFixed(1) ?? ''),
      'pantLength': TextEditingController(
          text: e?.pantLength?.toStringAsFixed(1) ?? ''),
      'vestLength': TextEditingController(
          text: e?.vestLength?.toStringAsFixed(1) ?? ''),
      'jacketLength': TextEditingController(
          text: e?.jacketLength?.toStringAsFixed(1) ?? ''),
      'tunicLength': TextEditingController(
          text: e?.tunicLength?.toStringAsFixed(1) ?? ''),
      'upperBodyLength': TextEditingController(
          text: e?.upperBodyLength?.toStringAsFixed(1) ?? ''),
      'shortLength': TextEditingController(
          text: e?.shortLength?.toStringAsFixed(1) ?? ''),
    };
    _notesController = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  double? _parse(String key) {
    final text = _controllers[key]!.text.trim();
    return text.isEmpty ? null : double.tryParse(text);
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final measurement = Measurement(
      id: widget.existing?.id,
      customerId: widget.customerId,
      chest: _parse('chest'),
      waist: _parse('waist'),
      hips: _parse('hips'),
      upperHeight: _parse('upperHeight'),
      lowerHeight: _parse('lowerHeight'),
      armLength: _parse('armLength'),
      skirtLength: _parse('skirtLength'),
      pantLength: _parse('pantLength'),
      vestLength: _parse('vestLength'),
      jacketLength: _parse('jacketLength'),
      tunicLength: _parse('tunicLength'),
      upperBodyLength: _parse('upperBodyLength'),
      shortLength: _parse('shortLength'),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: widget.existing?.createdAt,
    );

    if (_isEditing) {
      await ref
          .read(measurementProvider(widget.customerId).notifier)
          .updateMeasurement(measurement);
    } else {
      await ref
          .read(measurementProvider(widget.customerId).notifier)
          .addMeasurement(measurement);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _isEditing ? 'Ölçüyü Düzenle' : 'Ölçü Ekle',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MeasureField(
                    controller: _controllers['chest']!, label: 'Göğüs'),
                _MeasureField(
                    controller: _controllers['waist']!, label: 'Bel'),
                _MeasureField(
                    controller: _controllers['hips']!, label: 'Kalça'),
                _MeasureField(
                    controller: _controllers['upperHeight']!,
                    label: 'Üst boy'),
                _MeasureField(
                    controller: _controllers['lowerHeight']!,
                    label: 'Alt boy'),
                _MeasureField(
                    controller: _controllers['armLength']!,
                    label: 'Kol boy'),
                _MeasureField(
                    controller: _controllers['skirtLength']!,
                    label: 'Etek boy'),
                _MeasureField(
                    controller: _controllers['pantLength']!,
                    label: 'Pant boy'),
                _MeasureField(
                    controller: _controllers['vestLength']!,
                    label: 'Yelek boy'),
                _MeasureField(
                    controller: _controllers['jacketLength']!,
                    label: 'Çeket boy'),
                _MeasureField(
                    controller: _controllers['tunicLength']!,
                    label: 'Tunik boy'),
                _MeasureField(
                    controller: _controllers['upperBodyLength']!,
                    label: 'Üst beden'),
                _MeasureField(
                    controller: _controllers['shortLength']!,
                    label: 'Şort boy'),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Not (opsiyonel)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Güncelle' : 'Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Prova formu (ürün seçimli) ──────────────────────────────────────────────

class FittingFormSheet extends ConsumerStatefulWidget {
  final Customer customer;
  final List<Order> orders;
  const FittingFormSheet({
    super.key,
    required this.customer,
    required this.orders,
  });

  @override
  ConsumerState<FittingFormSheet> createState() => _FittingFormSheetState();
}

class _FittingFormSheetState extends ConsumerState<FittingFormSheet> {
  DateTime _fittingDate = DateTime.now().add(const Duration(days: 3));
  final _notesController = TextEditingController();
  Order? _selectedOrder;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _fittingDate.isBefore(today) ? today : _fittingDate,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today.add(const Duration(days: 365 * 2)),
      locale: const Locale('tr'),
    );
    if (picked != null) setState(() => _fittingDate = picked);
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final fitting = Fitting(
      customerId: widget.customer.id!,
      customerName: widget.customer.name,
      orderId: _selectedOrder?.id,
      productName: _selectedOrder?.productName,
      fittingDate: _fittingDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    await ref
        .read(fittingProvider(widget.customer.id!).notifier)
        .addFitting(fitting);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMMM yyyy', 'tr');
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Prova Ekle',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Ürün seçimi
            if (widget.orders.isNotEmpty) ...[
              DropdownButtonFormField<Order?>(
                initialValue: _selectedOrder,
                decoration: InputDecoration(
                  labelText: 'Ürün / Sipariş',
                  prefixIcon: const Icon(Icons.checkroom_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  const DropdownMenuItem<Order?>(
                    value: null,
                    child: Text('Ürün seçin (opsiyonel)'),
                  ),
                  ...widget.orders.map((o) => DropdownMenuItem<Order?>(
                        value: o,
                        child: Text(o.productName),
                      )),
                ],
                onChanged: (val) => setState(() => _selectedOrder = val),
              ),
              const SizedBox(height: 12),
            ],
            // Tarih seçimi
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Prova Tarihi'),
              subtitle: Text(
                dateFormat.format(_fittingDate),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.chevron_right),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 0.5,
                ),
              ),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Not (opsiyonel)',
                prefixIcon: const Icon(Icons.note_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.notifications_active_outlined),
                label: const Text('Kaydet & Bildirim Kur'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ölçü alanı ───────────────────────────────────────────────────────────────

class _MeasureField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _MeasureField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 52) / 2,
      child: TextField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: '$label (cm)',
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}
