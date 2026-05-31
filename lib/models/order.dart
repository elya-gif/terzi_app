enum OrderStatus { received, inProgress, ready, delivered }

extension OrderStatusExtension on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.received:    return 'Alındı';
      case OrderStatus.inProgress:  return 'Devam ediyor';
      case OrderStatus.ready:       return 'Hazır';
      case OrderStatus.delivered:   return 'Teslim edildi';
    }
  }

  String get value {
    return toString().split('.').last;
  }

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OrderStatus.received,
    );
  }
}

class Order {
  final int? id;
  final int customerId;
  final String customerName;
  final String productName;
  final double price;
  final OrderStatus status;
  final DateTime deliveryDate;
  final String? notes;
  final DateTime createdAt;

  Order({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.productName,
    required this.price,
    this.status = OrderStatus.received,
    required this.deliveryDate,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'product_name': productName,
      'price': price,
      'status': status.value,
      'delivery_date': deliveryDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      productName: map['product_name'],
      price: map['price']?.toDouble() ?? 0.0,
      status: OrderStatusExtension.fromString(map['status']),
      deliveryDate: DateTime.parse(map['delivery_date']),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Order copyWith({
    int? id,
    String? productName,
    double? price,
    OrderStatus? status,
    DateTime? deliveryDate,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId,
      customerName: customerName,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      status: status ?? this.status,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}