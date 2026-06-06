import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../models/measurement.dart';
import '../../models/order.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
            Tab(text: 'Notlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MeasurementsTab(customer: customer),
          _OrdersTab(customer: customer),
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
        }
        return const SizedBox.shrink();
      },
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
                if (measurement.shoulder != null)
                  _MeasureChip(label: 'Omuz', value: measurement.shoulder!),
                if (measurement.armLength != null)
                  _MeasureChip(label: 'Kol', value: measurement.armLength!),
                if (measurement.legLength != null)
                  _MeasureChip(label: 'Bacak', value: measurement.legLength!),
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
      case OrderStatus.inProgress: return Colors.orange;
      case OrderStatus.ready:      return Colors.green;
      case OrderStatus.delivered:  return Colors.grey;
      default:                     return Theme.of(context).colorScheme.primary;
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
    'shoulder': TextEditingController(),
    'armLength': TextEditingController(),
    'legLength': TextEditingController(),
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
      shoulder: _parse('shoulder'),
      armLength: _parse('armLength'),
      legLength: _parse('legLength'),
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
              _MeasureField(controller: _controllers['shoulder']!, label: 'Omuz'),
              _MeasureField(controller: _controllers['armLength']!, label: 'Kol boyu'),
              _MeasureField(controller: _controllers['legLength']!, label: 'Bacak boyu'),
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