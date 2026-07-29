import 'package:flutter/material.dart';

/// Single source of truth for color across Invois.
///
/// - [AppColors.primary] / [AppColors.brandAccent] are the fixed brand colors,
///   same in both themes.
/// - Semantic colors (success/warning/danger) come via [AppColors.success],
///   [AppColors.warning], [AppColors.danger] — pass the current [Brightness]
///   so the same *meaning* renders with light-theme or dark-theme-safe
///   contrast automatically. Never hardcode Colors.red/orange/green/etc.
///   elsewhere in the app; use these.
/// - Neutral surfaces/text follow the Slate scale and are best read off
///   `Theme.of(context).colorScheme` (wired up in main.dart), but the raw
///   values are exposed here too for the few places that need a literal.
class AppColors {
  // ---- Brand (fixed across themes) ----
  static const Color primary = Color(0xFF005A36); // Deep Green
  static const Color brandAccent = Color(0xFF10B981); // Emerald

  // ---- Semantic status, theme-aware ----
  static Color success(Brightness b) => b == Brightness.dark ? const Color(0xFF34D399) : const Color(0xFF10B981);
  static Color warning(Brightness b) => b == Brightness.dark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
  static Color danger(Brightness b) => b == Brightness.dark ? const Color(0xFFF87171) : const Color(0xFFDC2626);

  // ---- Category accents (Labor vs Material — a distinction, not a status) ----
  static Color laborAccent(Brightness b) => b == Brightness.dark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
  static Color materialAccent(Brightness b) => b == Brightness.dark ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9);

  // ---- Neutral scale (Slate) ----
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // ---- Surfaces, theme-aware ----
  static Color background(Brightness b) => b == Brightness.dark ? slate900 : slate50;
  static Color surface(Brightness b) => b == Brightness.dark ? slate800 : Colors.white;
  static Color surfaceVariant(Brightness b) => b == Brightness.dark ? slate700 : slate100;
  static Color border(Brightness b) => b == Brightness.dark ? slate700 : slate200;
  static Color textPrimary(Brightness b) => b == Brightness.dark ? slate50 : slate900;
  static Color textSecondary(Brightness b) => b == Brightness.dark ? slate400 : slate500;

  // Deprecated aliases kept temporarily so existing call sites don't break
  // while being migrated — prefer the theme-aware getters above.
  static const Color secondary = brandAccent;
  static const Color accent = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color darkBg = slate900;
  static const Color darkSurface = slate800;
  static const Color lightBg = slate50;
  static const Color lightSurface = Colors.white;
  static const Color slateCard = slate800;
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

class AppTypography {
  static const TextStyle headerStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.5,
  );

  static const TextStyle titleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.2,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.grey,
  );
}

class AppAnimation {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}
