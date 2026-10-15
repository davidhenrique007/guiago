import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../data/home_providers.dart';
import '../domain/home_snapshot.dart';

/// Thrown into the [AsyncValue] when the snapshot cannot be loaded,
/// so the UI can show the original [failure] in an error state.
class HomeLoadException implements Exception {
  const HomeLoadException(this.failure);

  final Failure failure;

  @override
  String toString() => 'HomeLoadException: ${failure.message}';
}

class HomeController extends AsyncNotifier<HomeSnapshot> {
  @override
  Future<HomeSnapshot> build() async {
    final Result<HomeSnapshot> result =
        await ref.read(homeServiceProvider).load();
    return switch (result) {
      Success<HomeSnapshot>(:final value) => value,
      Fail<HomeSnapshot>(:final failure) => throw HomeLoadException(failure),
    };
  }

  /// The screen calls this on pull-to-refresh, since occurrences may
  /// have resolved since the last load.
  void refresh() => ref.invalidateSelf();
}

final homeControllerProvider =
    AsyncNotifierProvider<HomeController, HomeSnapshot>(HomeController.new);
