import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../../scheduler/data/scheduler_providers.dart';
import '../../domain/recurrence_rule.dart';
import '../../domain/task_priority.dart';
import '../widgets/task_create_priority_selector.dart';
import '../widgets/task_create_recurrence_selector.dart';

/// Quick task creation (master spec §23): título, data, hora,
/// prioridade, recorrência, descrição opcional. Tolerância e snooze
/// ficam nos defaults do TaskEngine (15/10 min) — mínimo de fricção,
/// por desenho (§23).
///
/// Sem controller dedicado: é um único submit sem estado assíncrono
/// complexo, por isso o ConsumerStatefulWidget chama o TaskEngine
/// diretamente — o mesmo critério usado para não criar camadas sem
/// necessidade (secção 42, "não criar abstrações sem necessidade").
class TaskCreateScreen extends ConsumerStatefulWidget {
  const TaskCreateScreen({super.key});

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

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime get _scheduledAt => DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) setState(() => _time = picked);
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
    final result = await ref.read(taskEngineWithSchedulerProvider).createTask(
          title: title,
          description: description.isEmpty ? null : description,
          priority: _priority,
          recurrenceRule: _recurrence,
          scheduledAt: _scheduledAt,
        );

    if (!mounted) return;

    if (result.isFailure) {
      setState(() {
        _isSaving = false;
        _errorMessage =
            result.failureOrNull?.message ?? 'Não foi possível criar a tarefa.';
      });
      return;
    }

// Repõe o estado antes de sair para o botão nunca ficar preso em
// "loading" se o pop falhar ou for intercetado por outra rota.
    setState(() => _isSaving = false);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Nova tarefa', style: AppTypography.titleLarge),
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
            AppTextField(
              label: 'Descrição (opcional)',
              hint: 'Detalhes extra',
              controller: _descriptionController,
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
              label: 'Criar tarefa',
              onPressed: _isSaving ? null : _submit,
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
