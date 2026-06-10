class Measurement {
  final int? id;
  final int customerId;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? upperHeight;
  final double? lowerHeight;
  final double? armLength;
  final double? skirtLength;
  final double? pantLength;
  final double? vestLength;
  final double? jacketLength;
  final double? tunicLength;
  final String? notes;
  final DateTime createdAt;

  Measurement({
    this.id,
    required this.customerId,
    this.chest,
    this.waist,
    this.hips,
    this.upperHeight,
    this.lowerHeight,
    this.armLength,
    this.skirtLength,
    this.pantLength,
    this.vestLength,
    this.jacketLength,
    this.tunicLength,
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
      'upper_height': upperHeight,
      'lower_height': lowerHeight,
      'arm_length': armLength,
      'skirt_length': skirtLength,
      'pant_length': pantLength,
      'vest_length': vestLength,
      'jacket_length': jacketLength,
      'tunic_length': tunicLength,
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
      upperHeight: map['upper_height']?.toDouble(),
      lowerHeight: map['lower_height']?.toDouble(),
      armLength: map['arm_length']?.toDouble(),
      skirtLength: map['skirt_length']?.toDouble(),
      pantLength: map['pant_length']?.toDouble(),
      vestLength: map['vest_length']?.toDouble(),
      jacketLength: map['jacket_length']?.toDouble(),
      tunicLength: map['tunic_length']?.toDouble(),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}