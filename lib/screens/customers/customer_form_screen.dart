import 'package:flutter/material.dart';
import '../../models/customer.dart';
class CustomerFormScreen extends StatelessWidget {
  final Customer? customer;
  const CustomerFormScreen({super.key, this.customer});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Müşteri')), body: const Center(child: Text('Form')));
}
