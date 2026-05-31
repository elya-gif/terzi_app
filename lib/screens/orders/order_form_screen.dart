import 'package:flutter/material.dart';
import '../../models/customer.dart';
import '../../models/order.dart';
class OrderFormScreen extends StatelessWidget {
  final Customer? customer;
  final Order? order;
  const OrderFormScreen({super.key, this.customer, this.order});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Sipariş')), body: const Center(child: Text('Form')));
}
