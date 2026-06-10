import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../providers/customer_provider.dart';

class OrderFormScreen extends ConsumerStatefulWidget {
  final Customer? customer;
  final Order? order;
  const OrderFormScreen({super.key, this.customer, this.order});

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _productController;
  late final TextEditingController _priceController;
  late final TextEditingController _notesController;
  Customer? _selectedCustomer;
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 7));
  OrderStatus _status = OrderStatus.received;
  bool _isLoading = false;

  bool get _isEditing => widget.order != null;

  @override
  void initState() {
    super.initState();
    _productController =
        TextEditingController(text: widget.order?.productName ?? '');
    _priceController = TextEditingController(
        text: widget.order != null
            ? widget.order!.price.toStringAsFixed(0)
            : '');
    _notesController =
        TextEditingController(text: widget.order?.notes ?? '');

    if (widget.customer != null) {
      _selectedCustomer = widget.customer;
    }
    if (widget.order != null) {
      _deliveryDate = widget.order!.deliveryDate;
      _status = widget.order!.status;
    }
  }

  @override
  void dispose() {
    _productController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _deliveryDate = picked);
  }

  Future<void> _pickCustomer() async {
    final customers = ref.read(customerListProvider);
    final result = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CustomerSearchSheet(customers: customers),
    );
    if (result != null) setState(() => _selectedCustomer = result);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen müşteri seçin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final order = Order(
      id: widget.order?.id,
      customerId: _selectedCustomer!.id!,
      customerName: _selectedCustomer!.name,
      productName: _productController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0,
      status: _status,
      deliveryDate: _deliveryDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (_isEditing) {
      await ref.read(orderListProvider.notifier).updateOrder(order);
    } else {
      await ref.read(orderListProvider.notifier).addOrder(order);
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMMM yyyy', 'tr');

    // Düzenlemede müşteri bilgisi order'dan gelir ama değiştirilebilir
    if (_isEditing && _selectedCustomer == null) {
      final customers = ref.read(customerListProvider);
      try {
        _selectedCustomer = customers
            .firstWhere((c) => c.id == widget.order!.customerId);
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Siparişi Düzenle' : 'Yeni Sipariş'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Müşteri seç (arama butonlu)
            GestureDetector(
              onTap: _pickCustomer,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Müşteri',
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  errorText: null,
                ),
                child: Text(
                  _selectedCustomer?.name ?? 'Müşteri seçmek için dokunun',
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedCustomer == null
                        ? Theme.of(context).colorScheme.outline
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Ürün adı
            TextFormField(
              controller: _productController,
              decoration: InputDecoration(
                labelText: 'Ürün / İş Tanımı',
                prefixIcon: const Icon(Icons.checkroom_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Ürün adı gerekli' : null,
            ),
            const SizedBox(height: 12),

            // Fiyat
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Ücret (₺)',
                prefixIcon: const Icon(Icons.payments_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Ücret gerekli' : null,
            ),
            const SizedBox(height: 12),

            // Teslim tarihi
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Teslim Tarihi'),
              subtitle: Text(dateFormat.format(_deliveryDate)),
              trailing: const Icon(Icons.chevron_right),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: Theme.of(context).colorScheme.outline, width: 0.5),
              ),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),

            // Durum (sadece alındı / teslim edildi)
            if (_isEditing) ...[
              DropdownButtonFormField<OrderStatus>(
                value: _status,
                decoration: InputDecoration(
                  labelText: 'Durum',
                  prefixIcon: const Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: OrderStatus.values.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s.label));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 12),
            ],

            // Notlar
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notlar (opsiyonel)',
                prefixIcon: const Icon(Icons.note_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? 'Güncelle' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Siparişi sil'),
        content: const Text('Bu siparişi silmek istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref
          .read(orderListProvider.notifier)
          .deleteOrder(widget.order!.id!);
      if (mounted) context.pop();
    }
  }
}

class _CustomerSearchSheet extends StatefulWidget {
  final List<Customer> customers;
  const _CustomerSearchSheet({required this.customers});

  @override
  State<_CustomerSearchSheet> createState() => _CustomerSearchSheetState();
}

class _CustomerSearchSheetState extends State<_CustomerSearchSheet> {
  final _searchController = TextEditingController();
  List<Customer> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.customers;
    _searchController.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = widget.customers
          .where((c) => c.name.toLowerCase().contains(q))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Müşteri ara...',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: _filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Müşteri bulunamadı'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final c = _filtered[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text(c.name[0])),
                        title: Text(c.name),
                        subtitle: Text(c.phone),
                        onTap: () => Navigator.pop(context, c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
