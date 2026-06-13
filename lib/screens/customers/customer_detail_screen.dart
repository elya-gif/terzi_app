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
            onPressed: () => context.push(
              '/customers/${customer.id}/edit',
              extra: customer,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
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
            onPressed: () => context.push('/orders/new', extra: widget.customer),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FittingFormSheet(customer: widget.customer),
    );
  }

  void _showMeasurementForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MeasurementFormSheet(customerId: widget.customer.id!),
    );
  }
}

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
            Icon(Icons.straighten, size: 56,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            const Text('Henüz ölçü yok'),
            const SizedBox(height: 8),
            Text('Aşağıdaki butona bas',
                style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: measurements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) =>
          _MeasurementCard(measurement: measurements[index]),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final Measurement measurement;
  const _MeasurementCard({required this.measurement});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMMM yyyy', 'tr').format(measurement.createdAt);

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
                Text(date,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline)),
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
                  _MeasureChip(label: 'Üst boy', value: measurement.upperHeight!),
                if (measurement.lowerHeight != null)
                  _MeasureChip(label: 'Alt boy', value: measurement.lowerHeight!),
                if (measurement.armLength != null)
                  _MeasureChip(label: 'Kol boy', value: measurement.armLength!),
                if (measurement.skirtLength != null)
                  _MeasureChip(label: 'Etek boy', value: measurement.skirtLength!),
                if (measurement.pantLength != null)
                  _MeasureChip(label: 'Pant boy', value: measurement.pantLength!),
                if (measurement.vestLength != null)
                  _MeasureChip(label: 'Yelek boy', value: measurement.vestLength!),
                if (measurement.jacketLength != null)
                  _MeasureChip(label: 'Çeket boy', value: measurement.jacketLength!),
                if (measurement.tunicLength != null)
                  _MeasureChip(label: 'Tunik boy', value: measurement.tunicLength!),
              ],
            ),
            if (measurement.notes != null && measurement.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(measurement.notes!,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline)),
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
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSecondaryContainer)),
          Text('${value.toStringAsFixed(1)} cm',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSecondaryContainer)),
        ],
      ),
    );
  }
}

class _OrdersTab extends ConsumerWidget {
  final Customer customer;
  const _OrdersTab({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allOrders = ref.watch(orderListProvider);
    final orders =
        allOrders.where((o) => o.customerId == customer.id).toList();

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

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          child: ListTile(
            title: Text(order.productName,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(
                DateFormat('d MMM yyyy', 'tr').format(order.deliveryDate)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₺${order.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                _StatusBadge(status: order.status),
              ],
            ),
            onTap: () =>
                context.push('/orders/${order.id}/edit', extra: order),
          ),
        );
      },
    );
  }
}

class _NotesTab extends StatelessWidget {
  final Customer customer;
  const _NotesTab({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: customer.notes == null || customer.notes!.isEmpty
          ? Center(
              child: Text('Not yok',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.outline)),
            )
          : Text(customer.notes!, style: const TextStyle(fontSize: 15)),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Color _color(BuildContext context) {
    switch (status) {
      case OrderStatus.delivered: return Colors.grey;
      default:                    return Theme.of(context).colorScheme.primary;
    }
  }
}

class MeasurementFormSheet extends ConsumerStatefulWidget {
  final int customerId;
  const MeasurementFormSheet({super.key, required this.customerId});

  @override
  ConsumerState<MeasurementFormSheet> createState() =>
      _MeasurementFormSheetState();
}

class _MeasurementFormSheetState extends ConsumerState<MeasurementFormSheet> {
  final Map<String, TextEditingController> _controllers = {
    'chest': TextEditingController(),
    'waist': TextEditingController(),
    'hips': TextEditingController(),
    'upperHeight': TextEditingController(),
    'lowerHeight': TextEditingController(),
    'armLength': TextEditingController(),
    'skirtLength': TextEditingController(),
    'pantLength': TextEditingController(),
    'vestLength': TextEditingController(),
    'jacketLength': TextEditingController(),
    'tunicLength': TextEditingController(),
  };
  final _notesController = TextEditingController();
  bool _isLoading = false;

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
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    await ref
        .read(measurementProvider(widget.customerId).notifier)
        .addMeasurement(measurement);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Ölçü Ekle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MeasureField(controller: _controllers['chest']!, label: 'Göğüs'),
              _MeasureField(controller: _controllers['waist']!, label: 'Bel'),
              _MeasureField(controller: _controllers['hips']!, label: 'Kalça'),
              _MeasureField(controller: _controllers['upperHeight']!, label: 'Üst boy'),
              _MeasureField(controller: _controllers['lowerHeight']!, label: 'Alt boy'),
              _MeasureField(controller: _controllers['armLength']!, label: 'Kol boy'),
              _MeasureField(controller: _controllers['skirtLength']!, label: 'Etek boy'),
              _MeasureField(controller: _controllers['pantLength']!, label: 'Pant boy'),
              _MeasureField(controller: _controllers['vestLength']!, label: 'Yelek boy'),
              _MeasureField(controller: _controllers['jacketLength']!, label: 'Çeket boy'),
              _MeasureField(controller: _controllers['tunicLength']!, label: 'Tunik boy'),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Not (opsiyonel)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
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
                  : const Text('Kaydet'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FittingsTab extends ConsumerWidget {
  final Customer customer;
  const _FittingsTab({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fittings = ref.watch(fittingProvider(customer.id!));
    final dateFormat = DateFormat('d MMMM yyyy', 'tr');

    if (fittings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.content_cut, size: 56,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            const Text('Henüz prova yok'),
            const SizedBox(height: 8),
            Text('Aşağıdaki butona bas',
                style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: fittings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final fitting = fittings[index];
        final isPast = fitting.fittingDate.isBefore(DateTime.now());
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPast
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.content_cut,
                  size: 20,
                  color: isPast
                      ? Theme.of(context).colorScheme.outline
                      : Theme.of(context).colorScheme.primary),
            ),
            title: Text(dateFormat.format(fitting.fittingDate),
                style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: fitting.notes != null && fitting.notes!.isNotEmpty
                ? Text(fitting.notes!, maxLines: 1, overflow: TextOverflow.ellipsis)
                : null,
            trailing: isPast
                ? Text('Geçti',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline))
                : Text(
                    _daysUntil(fitting.fittingDate),
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500),
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

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Fitting fitting) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Provayı sil'),
        content: const Text('Bu provayı silmek istediğine emin misin?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
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
      await ref.read(fittingProvider(customer.id!).notifier).deleteFitting(fitting.id!);
    }
  }
}

class FittingFormSheet extends ConsumerStatefulWidget {
  final Customer customer;
  const FittingFormSheet({super.key, required this.customer});

  @override
  ConsumerState<FittingFormSheet> createState() => _FittingFormSheetState();
}

class _FittingFormSheetState extends ConsumerState<FittingFormSheet> {
  DateTime _fittingDate = DateTime.now().add(const Duration(days: 3));
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fittingDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _fittingDate = picked);
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final fitting = Fitting(
      customerId: widget.customer.id!,
      customerName: widget.customer.name,
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
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Prova Ekle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
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
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      child: CircularProgressIndicator(strokeWidth: 2))
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
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: '$label (cm)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}