class Measurement {
  final int? id;
  final int customerId;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? shoulder;
  final double? armLength;
  final double? legLength;
  final String? notes;
  final DateTime createdAt;

  Measurement({
    this.id,
    required this.customerId,
    this.chest,
    this.waist,
    this.hips,
    this.shoulder,
    this.armLength,
    this.legLength,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'chest': chest,
      'waist': waist,
      'hips': hips,
      'shoulder': shoulder,
      'arm_length': armLength,
      'leg_length': legLength,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Measurement.fromMap(Map<String, dynamic> map) {
    return Measurement(
      id: map['id'],
      customerId: map['customer_id'],
      chest: map['chest']?.toDouble(),
      waist: map['waist']?.toDouble(),
      hips: map['hips']?.toDouble(),
      shoulder: map['shoulder']?.toDouble(),
      armLength: map['arm_length']?.toDouble(),
      legLength: map['leg_length']?.toDouble(),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}