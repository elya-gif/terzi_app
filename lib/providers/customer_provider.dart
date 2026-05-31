import 'package:flutter_riverpod/legacy.dart';
import '../db/database_helper.dart';
import '../models/customer.dart';

final customerListProvider =
    StateNotifierProvider<CustomerNotifier, List<Customer>>((ref) {
  return CustomerNotifier();
});

class CustomerNotifier extends StateNotifier<List<Customer>> {
  CustomerNotifier() : super([]) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    final customers = await DatabaseHelper.instance.getAllCustomers();
    state = customers;
  }

  Future<void> addCustomer(Customer customer) async {
    final id = await DatabaseHelper.instance.insertCustomer(customer);
    final newCustomer = customer.copyWith(id: id);
    state = [...state, newCustomer];
    state = [...state]..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> updateCustomer(Customer customer) async {
    await DatabaseHelper.instance.updateCustomer(customer);
    state = state.map((c) => c.id == customer.id ? customer : c).toList();
  }

  Future<void> deleteCustomer(int id) async {
    await DatabaseHelper.instance.deleteCustomer(id);
    state = state.where((c) => c.id != id).toList();
  }
}