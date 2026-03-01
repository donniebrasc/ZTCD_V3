import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Dark bordered panel — the basic "card" for all automotive pages.
class DashCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DashCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A38)),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Glowing LED status dot used throughout the dashboard.
class StatusLed extends StatelessWidget {
  final Color color;
  const StatusLed({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.7), blurRadius: 6, spreadRadius: 1),
        ],
      ),
    );
  }
}

/// Automotive-styled outlined action button with a coloured accent border.
class AutomotiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final bool loading;

  const AutomotiveButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final effectiveColor = disabled ? AppTheme.onSurfaceDim : color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVar,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: effectiveColor.withOpacity(0.6)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: effectiveColor),
                )
              else
                Icon(icon, size: 18, color: effectiveColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.rajdhani(
                  color: effectiveColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
