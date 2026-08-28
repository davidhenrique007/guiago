import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_environment.freezed.dart';

/// Which build flavor GuiaGo is currently running as.
///
/// This is the Fase 0 proof that Freezed + build_runner are correctly
/// wired end to end. Future request/response and domain models
/// (Task, TaskOccurrence, etc. — Fase 2) will follow this same pattern.
@freezed
sealed class AppEnvironment with _$AppEnvironment {
  const factory AppEnvironment({
    required AppFlavor flavor,
    required bool isDebug,
  }) = _AppEnvironment;

  const AppEnvironment._();

  static const AppEnvironment development = AppEnvironment(
    flavor: AppFlavor.development,
    isDebug: true,
  );

  static const AppEnvironment production = AppEnvironment(
    flavor: AppFlavor.production,
    isDebug: false,
  );
}

enum AppFlavor { development, staging, production }
