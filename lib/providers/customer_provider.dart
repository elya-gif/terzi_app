import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../services/firestore_sync_service.dart';
import 'order_provider.dart';

final customerListProvider =
    NotifierProvider<CustomerNotifier, List<Customer>>(CustomerNotifier.new);

class CustomerNotifier extends Notifier<List<Customer>> {
  @override
  List<Customer> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final customers = await FirestoreSyncService.instance.getAllCustomers();
    state = customers;
  }

  Future<void> addCustomer(Customer customer) async {
    final id = await FirestoreSyncService.instance.nextId('customers');
    final newCustomer = customer.copyWith(id: id);
    state = [...state, newCustomer]..sort((a, b) => a.name.compareTo(b.name));
    await FirestoreSyncService.instance.upsertCustomer(newCustomer);
  }

  Future<void> updateCustomer(Customer customer) async {
    state = state.map((c) => c.id == customer.id ? customer : c).toList();
    await FirestoreSyncService.instance.upsertCustomer(customer);
  }

  Future<void> deleteCustomer(int id) async {
    state = state.where((c) => c.id != id).toList();
    await FirestoreSyncService.instance.deleteCustomerCascade(id);
  }
}

final orderCountProvider = Provider.family<int, int>((ref, customerId) {
  final orders = ref.watch(orderListProvider);
  return orders.where((o) => o.customerId == customerId).length;
});
