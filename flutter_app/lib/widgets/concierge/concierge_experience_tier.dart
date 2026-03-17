import 'package:flutter/material.dart';

import '../../config/theme.dart';

class ConciergeExperienceTier extends StatelessWidget {
  final List<Map<String, dynamic>> tiers;
  final String? note;
  final void Function(String tierId) onSelect;

  const ConciergeExperienceTier({
    super.key,
    required this.tiers,
    this.note,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...tiers.map((tier) {
          final id = tier['id'] as String? ?? '';
          final label = tier['label'] as String? ?? '';
          final price = tier['price'] as int? ?? 0;
          final highlighted = tier['highlighted'] as bool? ?? false;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => onSelect(id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: highlighted
                      ? CoreSyncColors.accent.withAlpha(12)
                      : CoreSyncColors.glass,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: highlighted
                        ? CoreSyncColors.accent.withAlpha(60)
                        : CoreSyncColors.glassBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: highlighted ? FontWeight.w500 : FontWeight.w400,
                        color: CoreSyncColors.textPrimary,
                      ),
                    ),
                    Text(
                      '\$$price',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: CoreSyncColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              note!,
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: CoreSyncColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}
