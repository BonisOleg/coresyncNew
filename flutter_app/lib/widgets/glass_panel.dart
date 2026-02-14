import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Glass-morphism panel widget matching the website's glass panel aesthetic.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CoreSyncTheme.glassColor.withAlpha(200),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: CoreSyncTheme.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}
