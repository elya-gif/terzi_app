class Customer {
  final int? id;
  final String name;
  final String phone;
  final String? address;
  final String? notes;
  final DateTime createdAt;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.address,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? notes,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}