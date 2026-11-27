import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/app_localizations.dart';

/// What the user typed in [ProfileEditSheet].
typedef ProfileEdit = ({String name, String objective});

/// Bottom sheet to change the name and the main objective. Returns
/// null when dismissed. The name is required; the objective is not.
abstract final class ProfileEditSheet {
  static Future<ProfileEdit?> show(
    BuildContext context, {
    required String name,
    required String objective,
  }) {
    return AppBottomSheet.show<ProfileEdit>(
      context,
      title: context.l10n.profileEditTitle,
      child: _EditForm(name: name, objective: objective),
    );
  }
}

class _EditForm extends StatefulWidget {
  const _EditForm({required this.name, required this.objective});

  final String name;
  final String objective;

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  late final TextEditingController _name = TextEditingController(
    text: widget.name,
  );
  late final TextEditingController _objective = TextEditingController(
    text: widget.objective,
  );
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _objective.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = context.l10n.nameRequired);
      return;
    }
    Navigator.of(context).pop((name: name, objective: _objective.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          label: context.l10n.fieldName,
          controller: _name,
          errorText: _nameError,
          autofocus: true,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: context.l10n.fieldObjective,
          controller: _objective,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(label: context.l10n.commonSave, onPressed: _submit),
      ],
    );
  }
}
