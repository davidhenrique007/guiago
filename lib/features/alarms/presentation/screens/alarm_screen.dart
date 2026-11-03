import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../design_system/design_system.dart';
import '../../application/alarm_ring_controller.dart';
import '../../domain/decline_reason.dart';
import '../widgets/decline_reason_sheet.dart';

/// The alarm-ringing screen (master spec §24): shows the task,
/// speaks it aloud, and offers Concluída / Adiar / Não Vou.
class AlarmScreen extends ConsumerWidget {
  const AlarmScreen({required this.occurrenceId, super.key});

  final String occurrenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AlarmRingUiState> state =
        ref.watch(alarmRingControllerProvider(occurrenceId));

    ref.listen<AsyncValue<AlarmRingUiState>>(
      alarmRingControllerProvider(occurrenceId),
      (
        AsyncValue<AlarmRingUiState>? previous,
        AsyncValue<AlarmRingUiState> next,
      ) {
        final bool resolved = switch (next) {
          AsyncData<AlarmRingUiState>(:final value) => value.isResolved,
          _ => false,
        };
        if (resolved && context.mounted) {
          context.go(AppRoutes.home);
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: state.when(
          loading: () => const AppLoadingState(),
          error: (Object error, StackTrace stackTrace) => AppErrorState(
            message: 'Não foi possível abrir o alarme.',
            onRetry: () =>
                ref.invalidate(alarmRingControllerProvider(occurrenceId)),
          ),
          data: (AlarmRingUiState uiState) => _AlarmRingBody(
            uiState: uiState,
            onComplete: () => ref
                .read(alarmRingControllerProvider(occurrenceId).notifier)
                .complete(),
            onSnooze: () => ref
                .read(alarmRingControllerProvider(occurrenceId).notifier)
                .snooze(),
            onDecline: () async {
              final DeclineReason? reason =
                  await showDeclineReasonSheet(context);
              if (reason != null) {
                await ref
                    .read(alarmRingControllerProvider(occurrenceId).notifier)
                    .decline(reason);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _AlarmRingBody extends StatelessWidget {
  const _AlarmRingBody({
    required this.uiState,
    required this.onComplete,
    required this.onSnooze,
    required this.onDecline,
  });

  final AlarmRingUiState uiState;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;
  final Future<void> Function() onDecline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'GuiaGo',
            style: AppTypography.label,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            uiState.task.title,
            style: AppTypography.displayLarge,
            textAlign: TextAlign.center,
          ),
          if (uiState.task.description != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              uiState.task.description!,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          AppButton(label: 'Concluída', onPressed: onComplete),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Adiar',
            variant: AppButtonVariant.secondary,
            onPressed: onSnooze,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Não vou',
            variant: AppButtonVariant.secondary,
            onPressed: onDecline,
          ),
        ],
      ),
    );
  }
}
