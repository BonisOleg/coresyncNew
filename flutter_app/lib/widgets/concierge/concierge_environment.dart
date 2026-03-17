import 'package:flutter/material.dart';

import '../../config/theme.dart';

class ConciergeEnvironment extends StatelessWidget {
  final List<Map<String, dynamic>> scenes;
  final void Function(String sceneId) onSelect;

  const ConciergeEnvironment({
    super.key,
    required this.scenes,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.3,
          ),
          itemCount: scenes.length,
          itemBuilder: (context, index) {
            final scene = scenes[index];
            final id = scene['id'] as String? ?? '';
            final name = scene['name'] as String? ?? '';
            final thumb = scene['thumbnail_url'] as String? ?? '';

            return GestureDetector(
              onTap: () => onSelect(id),
              child: Container(
                decoration: BoxDecoration(
                  color: CoreSyncColors.glass,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CoreSyncColors.glassBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: thumb.isNotEmpty
                          ? Image.network(thumb, fit: BoxFit.cover)
                          : Container(
                              color: CoreSyncColors.surface,
                              child: const Icon(
                                Icons.landscape_outlined,
                                color: CoreSyncColors.textMuted,
                              ),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CoreSyncColors.textPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => onSelect(''),
          child: const Text(
            'Skip — use default',
            style: TextStyle(color: CoreSyncColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
