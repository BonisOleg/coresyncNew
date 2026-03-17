import 'package:flutter/material.dart';

import '../../config/theme.dart';

class ConciergeTimeSlots extends StatelessWidget {
  final List<Map<String, dynamic>> slots;
  final void Function(String timeStart) onSelect;

  const ConciergeTimeSlots({
    super.key,
    required this.slots,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: slots.map((slot) {
        final display = slot['display'] as String? ?? slot['time_start'] as String? ?? '';
        final timeStart = slot['time_start'] as String? ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            onPressed: () => onSelect(timeStart),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: CoreSyncColors.glassBorder),
              foregroundColor: CoreSyncColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              display,
              style: const TextStyle(fontSize: 15, letterSpacing: 1),
            ),
          ),
        );
      }).toList(),
    );
  }
}
