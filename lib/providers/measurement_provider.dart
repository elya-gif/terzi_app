import 'package:flutter_riverpod/legacy.dart';
import '../models/measurement.dart';
import '../db/database_helper.dart';

final measurementProvider = StateNotifierProvider.family<
    MeasurementNotifier, List<Measurement>, int>((ref, customerId) {
  return MeasurementNotifier(customerId);
});

class MeasurementNotifier extends StateNotifier<List<Measurement>> {
  final int customerId;

  MeasurementNotifier(this.customerId) : super([]) {
    loadMeasurements();
  }

  Future<void> loadMeasurements() async {
    final measurements =
        await DatabaseHelper.instance.getMeasurements(customerId);
    state = measurements;
  }

  Future<void> addMeasurement(Measurement measurement) async {
    final id = await DatabaseHelper.instance.insertMeasurement(measurement);
    final newMeasurement = Measurement(
      id: id,
      customerId: measurement.customerId,
      chest: measurement.chest,
      waist: measurement.waist,
      hips: measurement.hips,
      shoulder: measurement.shoulder,
      armLength: measurement.armLength,
      legLength: measurement.legLength,
      thigh: measurement.thigh,
      notes: measurement.notes,
      createdAt: measurement.createdAt,
    );
    state = [newMeasurement, ...state];
  }

  Future<void> updateMeasurement(Measurement measurement) async {
    await DatabaseHelper.instance.updateMeasurement(measurement);
    state = state
        .map((m) => m.id == measurement.id ? measurement : m)
        .toList();
  }
}
