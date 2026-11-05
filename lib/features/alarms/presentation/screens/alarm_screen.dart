import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/utils/pt_date_labels.dart';
import '../../../../design_system/design_system.dart';
import '../../application/alarm_ring_controller.dart';
import '../../domain/decline_reason.dart';
import '../widgets/decline_reason_sheet.dart';

/// The alarm-ringing screen (master spec §24): shows the task,
/// speaks it aloud, and offers Concluída / Adiar / Não vou fazer,
/// with the tolerance window shown underneath.
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
    final DateTime scheduledAt = uiState.occurrence.scheduledAt;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height -
              MediaQuery.paddingOf(context).vertical -
              AppSpacing.lg * 2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Center(child: _AlarmRing()),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Está na hora de',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.sm + 2),
            Text(
              '${PtDateLabels.time(scheduledAt)} · '
              '${PtDateLabels.dayAndMonthUpper(scheduledAt)}',
              style: AppTypography.mono.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Concluída',
              icon: Icons.check_rounded,
              onPressed: onComplete,
            ),
            const SizedBox(height: AppSpacing.sm + 3),
            AppButton(
              label: 'Adiar ${uiState.task.defaultSnoozeMinutes} min',
              icon: Icons.schedule_outlined,
              variant: AppButtonVariant.caution,
              onPressed: onSnooze,
            ),
            const SizedBox(height: AppSpacing.sm + 3),
            AppButton(
              label: 'Não vou fazer',
              icon: Icons.close_rounded,
              variant: AppButtonVariant.danger,
              onPressed: onDecline,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Tempo de tolerância: '
              '${uiState.occurrence.toleranceMinutes} min',
              style: AppTypography.bodyMedium.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// The amber bell with a soft halo.
class _AlarmRing extends StatelessWidget {
  const _AlarmRing();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            AppColors.accent.withValues(alpha: 0.22),
            Colors.transparent,
          ],
          stops: const <double>[0, 0.7],
        ),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: const Icon(
        Icons.notifications_none_rounded,
        size: 40,
        color: AppColors.accent,
      ),
    );
  }
}
