import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  final ValueChanged<OrderStatus> onStatusChanged;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onStatusChanged,
  });

  Color _statusColor(BuildContext context) {
    switch (order.status) {
      case OrderStatus.delivered: return Colors.grey;
      case OrderStatus.received:  return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy', 'tr');
    final color = _statusColor(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.productName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.status.label,
                      style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    order.customerName,
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(order.deliveryDate),
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline),
                  ),
                  const Spacer(),
                  Text(
                    '₺${order.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}