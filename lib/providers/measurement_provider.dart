import 'package:flutter_riverpod/legacy.dart';
import '../models/measurement.dart';
import '../services/firestore_sync_service.dart';

final measurementProvider = StateNotifierProvider.family<
    MeasurementNotifier, List<Measurement>, int>((ref, customerId) {
  return MeasurementNotifier(customerId);
});

class MeasurementNotifier extends StateNotifier<List<Measurement>> {
  final int customerId;

  MeasurementNotifier(this.customerId) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final measurements =
        await FirestoreSyncService.instance.getMeasurements(customerId);
    state = measurements;
  }

  Future<void> addMeasurement(Measurement measurement) async {
    final id = await FirestoreSyncService.instance.nextId('measurements');
    final saved = Measurement(
      id: id,
      customerId: measurement.customerId,
      chest: measurement.chest,
      waist: measurement.waist,
      hips: measurement.hips,
      upperHeight: measurement.upperHeight,
      lowerHeight: measurement.lowerHeight,
      armLength: measurement.armLength,
      skirtLength: measurement.skirtLength,
      pantLength: measurement.pantLength,
      vestLength: measurement.vestLength,
      jacketLength: measurement.jacketLength,
      tunicLength: measurement.tunicLength,
      upperBodyLength: measurement.upperBodyLength,
      shortLength: measurement.shortLength,
      notes: measurement.notes,
      createdAt: measurement.createdAt,
    );
    state = [saved, ...state];
    await FirestoreSyncService.instance.upsertMeasurement(saved);
  }

  Future<void> updateMeasurement(Measurement measurement) async {
    state = state.map((m) => m.id == measurement.id ? measurement : m).toList();
    await FirestoreSyncService.instance.upsertMeasurement(measurement);
  }
}
