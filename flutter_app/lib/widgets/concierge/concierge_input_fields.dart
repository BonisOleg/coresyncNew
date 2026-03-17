import 'package:flutter/material.dart';

import '../../config/theme.dart';

class ConciergeInputFields extends StatefulWidget {
  final List<Map<String, dynamic>> fields;
  final String submitLabel;
  final String? skipLabel;
  final void Function(Map<String, String> values) onSubmit;
  final VoidCallback? onSkip;

  const ConciergeInputFields({
    super.key,
    required this.fields,
    required this.submitLabel,
    this.skipLabel,
    required this.onSubmit,
    this.onSkip,
  });

  @override
  State<ConciergeInputFields> createState() => _ConciergeInputFieldsState();
}

class _ConciergeInputFieldsState extends State<ConciergeInputFields> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final f in widget.fields)
        f['name'] as String: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleSubmit() {
    final values = <String, String>{};
    for (final entry in _controllers.entries) {
      values[entry.key] = entry.value.text.trim();
    }
    widget.onSubmit(values);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...widget.fields.map((field) {
          final name = field['name'] as String;
          final label = field['label'] as String? ?? name;
          final type = field['type'] as String? ?? 'text';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _controllers[name],
              keyboardType: type == 'tel'
                  ? TextInputType.phone
                  : type == 'email'
                      ? TextInputType.emailAddress
                      : TextInputType.text,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  color: CoreSyncColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: CoreSyncColors.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: CoreSyncColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: CoreSyncColors.accent),
                ),
                filled: true,
                fillColor: CoreSyncColors.glass,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
        ElevatedButton(
          onPressed: _handleSubmit,
          child: Text(widget.submitLabel),
        ),
        if (widget.skipLabel != null) ...[
          const SizedBox(height: 6),
          TextButton(
            onPressed: widget.onSkip,
            child: Text(
              widget.skipLabel!,
              style: const TextStyle(color: CoreSyncColors.textSecondary),
            ),
          ),
        ],
      ],
    );
  }
}
