import 'package:flutter/material.dart';

import '../../config/theme.dart';

class ConciergeSummary extends StatefulWidget {
  final Map<String, dynamic> uiData;
  final VoidCallback onPay;

  const ConciergeSummary({
    super.key,
    required this.uiData,
    required this.onPay,
  });

  @override
  State<ConciergeSummary> createState() => _ConciergeSummaryState();
}

class _ConciergeSummaryState extends State<ConciergeSummary> {
  bool _termsAccepted = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.uiData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CoreSyncColors.glass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CoreSyncColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CORESYNC PRIVATE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: CoreSyncColors.accent,
                ),
              ),
              const SizedBox(height: 12),
              _row('Date', data['date'] as String? ?? ''),
              _row('Time', data['time'] as String? ?? ''),
              _row('Experience', data['experience_tier'] as String? ?? ''),
              if ((data['food_preference'] as String? ?? '').isNotEmpty)
                _row('Preference', data['food_preference'] as String),
              const Divider(color: CoreSyncColors.glassBorder, height: 20),
              _row('Total', '\$${data['price']}', isBold: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _termsAccepted,
              onChanged: (v) => setState(() => _termsAccepted = v ?? false),
              activeColor: CoreSyncColors.accent,
              side: BorderSide(color: CoreSyncColors.glassBorder),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'I agree to the Terms & Conditions and Cancellation Policy',
                  style: TextStyle(
                    fontSize: 12,
                    color: CoreSyncColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _termsAccepted ? widget.onPay : null,
          child: Text('Pay \$${data['price']}'),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: CoreSyncColors.textSecondary,
              fontWeight: isBold ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isBold ? CoreSyncColors.textPrimary : CoreSyncColors.textSecondary,
              fontWeight: isBold ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
