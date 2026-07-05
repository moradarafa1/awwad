import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/catalog/default_fields.dart';
import '../../core/custom_field.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/common.dart';

class FieldsManagerScreen extends ConsumerWidget {
  const FieldsManagerScreen({super.key});

  static const _groups = ['competing_response', 'environment_action'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final s = ref.watch(appControllerProvider);
    final ctrl = ref.read(appControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customizeFields)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final group in _groups) ...[
            Text(groupTitle(group, locale),
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.heading)),
            const SizedBox(height: 10),
            SectionCard(
              child: Column(
                children: [
                  ...s.allFields(group).map((f) => _fieldRow(context, ctrl, f, l10n)),
                  const Divider(),
                  _AddFieldRow(
                    hint: l10n.addFieldHint,
                    onAdd: (label) => ctrl.addField(group, label),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _fieldRow(BuildContext context, AppController ctrl, CustomField f,
      AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              f.label,
              style: TextStyle(
                fontSize: 13,
                color: f.hidden ? AppColors.muted : AppColors.text,
                decoration: f.hidden ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          IconButton(
            tooltip: f.hidden ? l10n.show : l10n.hide,
            icon: Icon(
                f.hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: f.hidden ? AppColors.muted : AppColors.accent),
            onPressed: () => ctrl.toggleFieldHidden(f.id),
          ),
          if (!f.isSystem)
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 20, color: AppColors.danger),
              onPressed: () => ctrl.deleteField(f.id),
            ),
        ],
      ),
    );
  }
}

class _AddFieldRow extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onAdd;
  const _AddFieldRow({required this.hint, required this.onAdd});
  @override
  State<_AddFieldRow> createState() => _AddFieldRowState();
}

class _AddFieldRowState extends State<_AddFieldRow> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    widget.onAdd(v);
    _ctrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            decoration: InputDecoration(hintText: widget.hint, isDense: true),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: _submit,
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(backgroundColor: AppColors.accent),
        ),
      ],
    );
  }
}
