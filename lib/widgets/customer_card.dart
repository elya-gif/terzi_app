import 'package:flutter/material.dart';
import '../models/customer.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final int orderCount;
  final VoidCallback onTap;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.orderCount,
    required this.onTap,
  });

  String get _initials {
    final parts = customer.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            _initials,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(customer.phone),
        trailing: orderCount > 0
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$orderCount sipariş',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}