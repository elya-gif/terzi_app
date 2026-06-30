import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/fitting.dart';
import '../services/firestore_sync_service.dart';
import '../services/notification_service.dart';

final allFittingsProvider =
    StateNotifierProvider<AllFittingsNotifier, List<Fitting>>((ref) {
  return AllFittingsNotifier();
});

class AllFittingsNotifier extends StateNotifier<List<Fitting>> {
  AllFittingsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final fittings = await FirestoreSyncService.instance.getAllFittings();
    state = fittings;
  }

  void reload() => _load();
}

// Belirli bir müşterinin en yakın gelecek provasını döndürür
final nextFittingProvider = Provider.family<Fitting?, int>((ref, customerId) {
  final fittings = ref.watch(allFittingsProvider);
  final now = DateTime.now();
  final upcoming = fittings
      .where((f) =>
          f.customerId == customerId &&
          !DateTime(f.fittingDate.year, f.fittingDate.month, f.fittingDate.day)
              .isBefore(DateTime(now.year, now.month, now.day)))
      .toList()
    ..sort((a, b) => a.fittingDate.compareTo(b.fittingDate));
  return upcoming.isEmpty ? null : upcoming.first;
});

final fittingProvider = StateNotifierProvider.family<
    FittingNotifier, List<Fitting>, int>((ref, customerId) {
  return FittingNotifier(customerId, ref);
});

class FittingNotifier extends StateNotifier<List<Fitting>> {
  final int customerId;
  final Ref _ref;

  FittingNotifier(this.customerId, this._ref) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final fittings =
        await FirestoreSyncService.instance.getFittings(customerId);
    state = fittings;
  }

  Future<void> addFitting(Fitting fitting) async {
    final id = await FirestoreSyncService.instance.nextId('fittings');
    final newFitting = fitting.copyWith(id: id);
    state = [...state, newFitting]
      ..sort((a, b) => a.fittingDate.compareTo(b.fittingDate));
    await NotificationService.instance.scheduleFittingReminder(newFitting);
    await FirestoreSyncService.instance.upsertFitting(newFitting);
    _ref.read(allFittingsProvider.notifier).reload();
  }

  Future<void> updateFitting(Fitting fitting) async {
    await NotificationService.instance.cancelFittingReminder(fitting.id!);
    await NotificationService.instance.scheduleFittingReminder(fitting);
    state = state.map((f) => f.id == fitting.id ? fitting : f).toList()
      ..sort((a, b) => a.fittingDate.compareTo(b.fittingDate));
    await FirestoreSyncService.instance.upsertFitting(fitting);
    _ref.read(allFittingsProvider.notifier).reload();
  }

  Future<void> deleteFitting(int id) async {
    await NotificationService.instance.cancelFittingReminder(id);
    state = state.where((f) => f.id != id).toList();
    await FirestoreSyncService.instance.deleteFitting(id);
    _ref.read(allFittingsProvider.notifier).reload();
  }
}
