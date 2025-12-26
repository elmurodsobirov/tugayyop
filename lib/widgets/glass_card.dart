import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:scada_mobile_app/theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16.0),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // Glass effect backup for older devices (semi-transparent slate)
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? ScadaTheme.glassBorder.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (borderColor ?? ScadaTheme.neonCyan).withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
