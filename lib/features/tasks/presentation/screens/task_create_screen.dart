import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../../onboarding/application/settings_controller.dart';
import '../../../onboarding/domain/day_window.dart';
import '../../../onboarding/domain/settings.dart';
import '../../../scheduler/data/alarm_permission_providers.dart';
import '../../../scheduler/data/scheduler_providers.dart';
import '../../application/tasks_view_state.dart';
import '../../data/tasks_list_providers.dart';
import '../../domain/recurrence_rule.dart';
import '../../domain/task_priority.dart';
import '../widgets/task_create_minutes_selector.dart';
import '../widgets/task_create_options.dart';
import '../widgets/task_create_priority_selector.dart';
import '../widgets/task_create_recurrence_selector.dart';

/// Quick task creation (master spec §23): título, data, hora,
/// prioridade, recorrência, descrição opcional, tolerância e snooze.
/// Tolerância e snooze começam nos valores guardados no onboarding
/// (Settings) e só se mexe neles se for preciso — mínimo de fricção
/// (§23).
///
/// Sem controller dedicado: é um único submit sem estado assíncrono
/// complexo, por isso o ConsumerStatefulWidget chama o TaskEngine
/// diretamente — o mesmo critério usado para não criar camadas sem
/// necessidade (secção 42, "não criar abstrações sem necessidade").
///
/// Com [taskId] o mesmo formulário edita uma tarefa existente (Fase 8):
/// carrega-a, e ao guardar usa `TaskEngine.editTask`, que reagenda o
/// alarme.
class TaskCreateScreen extends ConsumerStatefulWidget {
  const TaskCreateScreen({this.taskId, this.initialDate, super.key});

  /// Null = criar; preenchido = editar essa tarefa.
  final String? taskId;

  /// Ao criar, o dia já escolhido (vem do Calendário). Null = hoje. Datas
  /// futuras começam às 09:00; hoje começa daqui a uma hora.
  final DateTime? initialDate;

  @override
  ConsumerState<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends ConsumerState<TaskCreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 1)),
  );
  TaskPriority _priority = TaskPriority.values.first;
  RecurrenceRule _recurrence = const RecurrenceRule.none();

  /// True while a time suggested from the user's day is still to be
  /// applied (a future day opened from the Calendar).
  bool _suggestTime = false;

  /// Null = the user has not touched the chip, so the saved default
  /// from [Settings] applies.
  int? _toleranceMinutes;
  int? _snoozeMinutes;

  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.taskId != null;
  bool _isLoading = false;
  bool _loadFailed = false;

  /// False when an edited task has no pending occurrence (e.g. it was
  /// already completed): there is no time left to change.
  bool _canEditTime = true;

  @override
  void initState() {
    super.initState();
    final DateTime? initial = widget.initialDate;
    if (!_isEditing && initial != null) {
      _date = DateTime(initial.year, initial.month, initial.day);
      final DateTime today = DateTime.now();
      final bool isToday = _date.year == today.year &&
          _date.month == today.month &&
          _date.day == today.day;
      if (!isToday) {
        _time = const TimeOfDay(hour: 9, minute: 0);
        _suggestTime = true;
      }
    }
    // The settings may still be loading here, so the suggested time
    // (09:00, moved inside the user's day) is applied when they arrive,
    // unless the user has already picked a time.
    ref.listenManual<AsyncValue<Settings>>(
      settingsControllerProvider,
      (AsyncValue<Settings>? previous, AsyncValue<Settings> next) {
        if (!_suggestTime || next is! AsyncData<Settings>) return;
        _suggestTime = false;
        final int minutes = DayWindow.fromSettings(next.value).suggest(9 * 60);
        final TimeOfDay suggested =
            TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
        if (previous == null) {
          _time = suggested; // still inside initState: no rebuild needed
        } else {
          setState(() => _time = suggested);
        }
      },
      fireImmediately: true,
    );
    if (_isEditing) {
      _isLoading = true;
      _loadDraft();
    }
  }

  Future<void> _loadDraft() async {
    final result =
        await ref.read(tasksServiceProvider).loadForEdit(widget.taskId!);
    if (!mounted) return;
    final TaskEditDraft? draft = result.valueOrNull;
    if (draft == null) {
      setState(() {
        _isLoading = false;
        _loadFailed = true;
        _errorMessage = 'Não foi possível carregar a tarefa.';
      });
      return;
    }
    final DateTime? at = draft.scheduledAt;
    setState(() {
      _titleController.text = draft.task.title;
      _descriptionController.text = draft.task.description ?? '';
      _priority = draft.task.priority;
      _recurrence = draft.task.recurrenceRule;
      _toleranceMinutes = draft.task.defaultToleranceMinutes;
      _snoozeMinutes = draft.task.defaultSnoozeMinutes;
      if (at != null) {
        _date = at;
        _time = TimeOfDay.fromDateTime(at);
      } else {
        _canEditTime = false;
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// The saved settings, or the onboarding defaults while they load
  /// (or if they cannot be read) — creating a task never waits on it.
  Settings _settings({required bool watch}) {
    final AsyncValue<Settings> async = watch
        ? ref.watch(settingsControllerProvider)
        : ref.read(settingsControllerProvider);
    return switch (async) {
      AsyncData<Settings>(:final value) => value,
      _ => Settings.initial,
    };
  }

  DateTime get _scheduledAt => DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );

  Future<void> _pickDate() async {
    final DateTime base = DateTime.now().subtract(const Duration(days: 1));
    final DateTime limit = DateTime.now().add(const Duration(days: 365 * 5));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      // Editing a task that is already overdue must still open.
      firstDate: _date.isBefore(base) ? _date : base,
      lastDate: _date.isAfter(limit) ? _date : limit,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked == null) return;
    _suggestTime = false;
    setState(() => _time = picked);
  }

  Future<void> _submit() async {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Dá um título à tarefa.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final String description = _descriptionController.text.trim();
    final Settings settings = _settings(watch: false);
    final int tolerance = _toleranceMinutes ?? settings.defaultToleranceMinutes;
    final int snooze = _snoozeMinutes ?? settings.defaultSnoozeMinutes;
    final engine = ref.read(taskEngineWithSchedulerProvider);
    final result = _isEditing
        ? await engine.editTask(
            taskId: widget.taskId!,
            title: title,
            description: description.isEmpty ? null : description,
            priority: _priority,
            recurrenceRule: _recurrence,
            toleranceMinutes: tolerance,
            snoozeMinutes: snooze,
            scheduledAt: _canEditTime ? _scheduledAt : null,
          )
        : await engine.createTask(
            title: title,
            description: description.isEmpty ? null : description,
            priority: _priority,
            recurrenceRule: _recurrence,
            scheduledAt: _scheduledAt,
            toleranceMinutes: tolerance,
            snoozeMinutes: snooze,
          );

    if (!mounted) return;

    if (result.isFailure) {
      setState(() {
        _isSaving = false;
        _errorMessage = result.failureOrNull?.message ??
            (_isEditing
                ? 'Não foi possível guardar a tarefa.'
                : 'Não foi possível criar a tarefa.');
      });
      return;
    }

// Repõe o estado antes de sair para o botão nunca ficar preso em
// "loading" se o pop falhar ou for intercetado por outra rota.
    setState(() => _isSaving = false);

    // First task created: this is the moment alarms start to matter, so
    // ask for the permissions now (once per run, and only if enabled).
    if (!_isEditing && settings.notificationsEnabled) {
      final bool asked =
          await ref.read(alarmPermissionPrompterProvider).promptIfNeeded();
      if (asked) ref.invalidate(alarmPermissionStatusProvider);
      if (!mounted) return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text('Editar tarefa', style: AppTypography.titleLarge),
        ),
        body: const AppLoadingState(),
      );
    }
    final Settings settings = _settings(watch: true);
    final DayWindow dayWindow = DayWindow.fromSettings(settings);
    final int tolerance = _toleranceMinutes ?? settings.defaultToleranceMinutes;
    final int snooze = _snoozeMinutes ?? settings.defaultSnoozeMinutes;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _isEditing ? 'Editar tarefa' : 'Nova tarefa',
          style: AppTypography.titleLarge,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            AppTextField(
              label: 'Título',
              hint: 'O que precisas de fazer?',
              autofocus: true,
              controller: _titleController,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Descrição (opcional)',
              hint: 'Detalhes extra',
              controller: _descriptionController,
            ),
            if (_canEditTime) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              Text('Quando', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _PickerTile(
                      label: _dateLabel(_date),
                      icon: Icons.calendar_today_outlined,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PickerTile(
                      label: _time.format(context),
                      icon: Icons.schedule_outlined,
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              if (!dayWindow
                  .contains(_time.hour * 60 + _time.minute)) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Fora do teu dia (${dayWindow.label}). '
                  'Podes guardar na mesma.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.lg),
            Text('Prioridade', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TaskCreatePrioritySelector(
              selected: _priority,
              onChanged: (TaskPriority priority) =>
                  setState(() => _priority = priority),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Repetição', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TaskCreateRecurrenceSelector(
              selected: _recurrence,
              onChanged: (RecurrenceRule rule) =>
                  setState(() => _recurrence = rule),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Tolerância', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TaskCreateMinutesSelector(
              options: TaskCreateOptions.including(
                TaskCreateOptions.toleranceMinutes,
                tolerance,
              ),
              selected: tolerance,
              onChanged: (int minutes) =>
                  setState(() => _toleranceMinutes = minutes),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Snooze padrão', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TaskCreateMinutesSelector(
              options: TaskCreateOptions.including(
                TaskCreateOptions.snoozeMinutes,
                snooze,
              ),
              selected: snooze,
              onChanged: (int minutes) =>
                  setState(() => _snoozeMinutes = minutes),
            ),
            if (_errorMessage != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: _isEditing ? 'Guardar alterações' : 'Guardar tarefa',
              onPressed: (_isSaving || _loadFailed) ? null : _submit,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    final String d = date.day.toString().padLeft(2, '0');
    final String m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}
