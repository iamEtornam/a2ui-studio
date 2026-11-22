import 'package:flutter/material.dart';

/// Semantic color tokens matching Obsidian Kinetic IDE (dark) and Lumen Kinetic (light).
@immutable
class StudioColors extends ThemeExtension<StudioColors> {
  const StudioColors({
    required this.canvasBg,
    required this.panelBg,
    required this.elevatedBg,
    required this.codeBg,
    required this.borderSubtle,
    required this.borderStrong,
    required this.primaryAccent,
    required this.cyanAccent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.flutterBadge,
    required this.privateBadgeBg,
    required this.privateBadgeFg,
    required this.publicBadgeBg,
    required this.publicBadgeFg,
  });

  final Color canvasBg;
  final Color panelBg;
  final Color elevatedBg;
  final Color codeBg;
  final Color borderSubtle;
  final Color borderStrong;
  final Color primaryAccent;
  final Color cyanAccent;
  final Color success;
  final Color warning;
  final Color danger;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color flutterBadge;
  final Color privateBadgeBg;
  final Color privateBadgeFg;
  final Color publicBadgeBg;
  final Color publicBadgeFg;

  static const dark = StudioColors(
    canvasBg: Color(0xFF0B0F17),
    panelBg: Color(0xFF0F172A),
    elevatedBg: Color(0xFF182032),
    codeBg: Color(0xFF06090E),
    borderSubtle: Color(0xFF1E293B),
    borderStrong: Color(0xFF334155),
    primaryAccent: Color(0xFF6366F1),
    cyanAccent: Color(0xFF38BDF8),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    textPrimary: Color(0xFFE2E8F0),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    flutterBadge: Color(0xFF02569B),
    privateBadgeBg: Color(0x29F59E0B),
    privateBadgeFg: Color(0xFFFBBF24),
    publicBadgeBg: Color(0x2610B981),
    publicBadgeFg: Color(0xFF34D399),
  );

  static const light = StudioColors(
    canvasBg: Color(0xFFF8FAFC),
    panelBg: Color(0xFFFFFFFF),
    elevatedBg: Color(0xFFF1F5F9),
    codeBg: Color(0xFFF1F5F9),
    borderSubtle: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFCBD5E1),
    primaryAccent: Color(0xFF4F46E5),
    cyanAccent: Color(0xFF0284C7),
    success: Color(0xFF059669),
    warning: Color(0xFFD97706),
    danger: Color(0xFFDC2626),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF334155),
    textMuted: Color(0xFF64748B),
    flutterBadge: Color(0xFF02569B),
    privateBadgeBg: Color(0x1FD97706),
    privateBadgeFg: Color(0xFFB45309),
    publicBadgeBg: Color(0x1F059669),
    publicBadgeFg: Color(0xFF047857),
  );

  static StudioColors of(BuildContext context) {
    return Theme.of(context).extension<StudioColors>() ?? dark;
  }

  @override
  StudioColors copyWith({
    Color? canvasBg,
    Color? panelBg,
    Color? elevatedBg,
    Color? codeBg,
    Color? borderSubtle,
    Color? borderStrong,
    Color? primaryAccent,
    Color? cyanAccent,
    Color? success,
    Color? warning,
    Color? danger,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? flutterBadge,
    Color? privateBadgeBg,
    Color? privateBadgeFg,
    Color? publicBadgeBg,
    Color? publicBadgeFg,
  }) {
    return StudioColors(
      canvasBg: canvasBg ?? this.canvasBg,
      panelBg: panelBg ?? this.panelBg,
      elevatedBg: elevatedBg ?? this.elevatedBg,
      codeBg: codeBg ?? this.codeBg,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      primaryAccent: primaryAccent ?? this.primaryAccent,
      cyanAccent: cyanAccent ?? this.cyanAccent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      flutterBadge: flutterBadge ?? this.flutterBadge,
      privateBadgeBg: privateBadgeBg ?? this.privateBadgeBg,
      privateBadgeFg: privateBadgeFg ?? this.privateBadgeFg,
      publicBadgeBg: publicBadgeBg ?? this.publicBadgeBg,
      publicBadgeFg: publicBadgeFg ?? this.publicBadgeFg,
    );
  }

  @override
  StudioColors lerp(ThemeExtension<StudioColors>? other, double t) {
    if (other is! StudioColors) return this;
    return StudioColors(
      canvasBg: Color.lerp(canvasBg, other.canvasBg, t)!,
      panelBg: Color.lerp(panelBg, other.panelBg, t)!,
      elevatedBg: Color.lerp(elevatedBg, other.elevatedBg, t)!,
      codeBg: Color.lerp(codeBg, other.codeBg, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
      cyanAccent: Color.lerp(cyanAccent, other.cyanAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      flutterBadge: Color.lerp(flutterBadge, other.flutterBadge, t)!,
      privateBadgeBg: Color.lerp(privateBadgeBg, other.privateBadgeBg, t)!,
      privateBadgeFg: Color.lerp(privateBadgeFg, other.privateBadgeFg, t)!,
      publicBadgeBg: Color.lerp(publicBadgeBg, other.publicBadgeBg, t)!,
      publicBadgeFg: Color.lerp(publicBadgeFg, other.publicBadgeFg, t)!,
    );
  }
}
