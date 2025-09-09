
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = _statusStyle(status, cs);

    return Semantics(
      label: 'Status: ${style.label}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: style.bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: style.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (style.icon != null) ...[
              Icon(style.icon, size: 14, color: style.fg),
              const SizedBox(width: 6),
            ],
            Text(
              style.label,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: style.fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusStyle {
  final Color bg, fg, border;
  final String label;
  final IconData? icon;
  const _StatusStyle({
    required this.bg,
    required this.fg,
    required this.border,
    required this.label,
    this.icon,
  });
}

_StatusStyle _statusStyle(String raw, ColorScheme cs) {
  final s = raw.trim().toLowerCase();
  String label(String fallback) {
    if (raw.trim().isEmpty) return fallback;
    final r = raw.trim();
    return r[0].toUpperCase() + r.substring(1).toLowerCase();
  }

  switch (s) {
    case 'active':
    case 'success':
    case 'paid':
      return _StatusStyle(
        bg: cs.secondaryContainer,
        fg: cs.onSecondaryContainer,
        border: cs.secondary.withValues(alpha: .30),
        label: label('Active'),
        icon: Icons.check_circle,
      );

    case 'processing':
    case 'pending':
    case 'initiated':
      return _StatusStyle(
        bg: cs.tertiaryContainer,
        fg: cs.onTertiaryContainer,
        border: cs.tertiary.withValues(alpha: .30),
        label: label('Processing'),
        icon: Icons.hourglass_bottom,
      );

    case 'occupied':
      return _StatusStyle(
        bg: cs.primaryContainer,
        fg: cs.onPrimaryContainer,
        border: cs.primary.withValues(alpha: .30),
        label: label('Occupied'),
        icon: Icons.home_work,
      );

    case 'expired':
    case 'overdue':
      return _StatusStyle(
        bg: cs.errorContainer,
        fg: cs.onErrorContainer,
        border: cs.error.withValues(alpha: .30),
        label: label('Expired'),
        icon: Icons.schedule,
      );

    case 'failed':
    case 'failure':
    case 'cancelled':
    case 'canceled':
      return _StatusStyle(
        // use error tint for cancelled/failed; keep good contrast
        bg: cs.error.withValues(alpha: .10),
        fg: cs.onError,
        border: cs.error.withValues(alpha: .35),
        label: label('Failed'),
        icon: Icons.cancel,
      );

    default:
      return _StatusStyle(
        bg: cs.surfaceVariant,
        fg: cs.onSurfaceVariant,
        border: cs.outlineVariant,
        label: label('Unknown'),
        icon: Icons.help_outline,
      );
  }
}
