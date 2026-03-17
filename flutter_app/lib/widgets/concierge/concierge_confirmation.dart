import 'package:flutter/material.dart';

import '../../config/theme.dart';

class ConciergeConfirmation extends StatelessWidget {
  final Map<String, dynamic> uiData;
  final void Function(String flowStep, Map<String, dynamic> data)? onAction;

  const ConciergeConfirmation({
    super.key,
    required this.uiData,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CoreSyncColors.glass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CoreSyncColors.glassBorder),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CoreSyncColors.accent.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: CoreSyncColors.accent,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'SESSION CONFIRMED',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: CoreSyncColors.accent,
                ),
              ),
              const SizedBox(height: 16),
              _row('Date', uiData['date'] as String? ?? ''),
              _row('Time', uiData['time'] as String? ?? ''),
              _row('Experience', uiData['experience_tier'] as String? ?? ''),
              const Divider(color: CoreSyncColors.glassBorder, height: 20),
              _row('Confirmation', uiData['confirmation_number'] as String? ?? ''),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => onAction?.call(
            'environment',
            {'booking_id': uiData['booking_id'] ?? ''},
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: CoreSyncColors.accent.withAlpha(60)),
            foregroundColor: CoreSyncColors.accent,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('Select Environment'),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => onAction?.call('start_membership', {}),
          child: const Text(
            'View Membership',
            style: TextStyle(color: CoreSyncColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: CoreSyncColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, color: CoreSyncColors.textPrimary)),
        ],
      ),
    );
  }
}
