import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../data/dashboard_providers.dart';
import '../domain/dashboard_period.dart';
import '../domain/dashboard_snapshot.dart';

/// Thrown into the [AsyncValue] when the snapshot cannot be loaded, so
/// the UI can show the original [failure] in an error state.
class DashboardLoadException implements Exception {
  const DashboardLoadException(this.failure);

  final Failure failure;

  @override
  String toString() => 'DashboardLoadException: ${failure.message}';
}

/// One controller per [DashboardPeriod] (Riverpod family, same shape
/// as `AlarmRingController`: the argument arrives via the constructor).
class DashboardController extends AsyncNotifier<DashboardSnapshot> {
  DashboardController(this.period);

  final DashboardPeriod period;

  @override
  Future<DashboardSnapshot> build() async {
    final Result<DashboardSnapshot> result =
        await ref.read(dashboardServiceProvider).load(period);
    return switch (result) {
      Success<DashboardSnapshot>(:final value) => value,
      Fail<DashboardSnapshot>(:final failure) =>
        throw DashboardLoadException(failure),
    };
  }

  /// Re-reads everything. The screen calls this when it opens, since
  /// occurrences may have been resolved since the last load.
  void refresh() => ref.invalidateSelf();
}

final dashboardControllerProvider = AsyncNotifierProvider.family<
    DashboardController, DashboardSnapshot, DashboardPeriod>(
  DashboardController.new,
);
