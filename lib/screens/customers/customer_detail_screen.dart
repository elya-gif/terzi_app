import 'package:flutter/material.dart';
import '../../models/customer.dart';
class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;
  const CustomerDetailScreen({super.key, required this.customer});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(customer.name)), body: const Center(child: Text('Detay')));
}
