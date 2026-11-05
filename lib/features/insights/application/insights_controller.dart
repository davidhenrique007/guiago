import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../data/insights_providers.dart';
import '../domain/insights_snapshot.dart';

/// Thrown into the [AsyncValue] when the insights cannot be loaded.
class InsightsLoadException implements Exception {
  const InsightsLoadException(this.failure);

  final Failure failure;

  @override
  String toString() => 'InsightsLoadException: ${failure.message}';
}

class InsightsController extends AsyncNotifier<InsightsSnapshot> {
  @override
  Future<InsightsSnapshot> build() async {
    final Result<InsightsSnapshot> result =
        await ref.read(insightsServiceProvider).load();
    return switch (result) {
      Success<InsightsSnapshot>(:final value) => value,
      Fail<InsightsSnapshot>(:final failure) =>
        throw InsightsLoadException(failure),
    };
  }

  void refresh() => ref.invalidateSelf();
}

final insightsControllerProvider =
    AsyncNotifierProvider<InsightsController, InsightsSnapshot>(
  InsightsController.new,
);
