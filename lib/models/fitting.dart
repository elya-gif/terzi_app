class Fitting {
  final int? id;
  final int customerId;
  final String customerName;
  final int? orderId;
  final String? productName;
  final DateTime fittingDate;
  final String? notes;
  final DateTime createdAt;

  Fitting({
    this.id,
    required this.customerId,
    required this.customerName,
    this.orderId,
    this.productName,
    required this.fittingDate,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'order_id': orderId,
      'product_name': productName,
      'fitting_date': fittingDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Fitting.fromMap(Map<String, dynamic> map) {
    return Fitting(
      id: map['id'],
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      orderId: map['order_id'],
      productName: map['product_name'],
      fittingDate: DateTime.parse(map['fitting_date']),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Fitting copyWith({
    int? id,
    int? orderId,
    String? productName,
    DateTime? fittingDate,
    String? notes,
  }) {
    return Fitting(
      id: id ?? this.id,
      customerId: customerId,
      customerName: customerName,
      orderId: orderId ?? this.orderId,
      productName: productName ?? this.productName,
      fittingDate: fittingDate ?? this.fittingDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
