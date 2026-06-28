class PaymentRecord {
  final int? id;
  final int orderId;
  final double amount;
  final DateTime paidAt;

  PaymentRecord({
    this.id,
    required this.orderId,
    required this.amount,
    required this.paidAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'amount': amount,
      'paid_at': paidAt.toIso8601String(),
    };
  }

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      id: map['id'],
      orderId: map['order_id'],
      amount: map['amount']?.toDouble() ?? 0.0,
      paidAt: DateTime.parse(map['paid_at']),
    );
  }
}
