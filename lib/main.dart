import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart';
import 'services/storage_service.dart';
import 'views/main_tab_view.dart';
import 'widgets/app_design_system.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    const inputTheme = InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary, width: 2),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      filled: true,
      fillColor: AppColors.slate50,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

    // Chip theming is pinned explicitly (not left to Material defaults) so
    // ChoiceChips render on-brand everywhere without needing per-widget
    // overrides — see the "synchronize colors" fix history for why this
    // matters: M3's default chip colors previously came from a
    // wallpaper-derived dynamic ColorScheme and looked inconsistent/wrong.
    ChipThemeData chipTheme(Brightness brightness) => ChipThemeData(
          backgroundColor: AppColors.surfaceVariant(brightness),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(color: AppColors.textPrimary(brightness), fontWeight: FontWeight.w600),
          secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        );

    return MaterialApp(
      title: 'Invois - Kenya Invoicing App',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        // Fixed brand palette — never device/wallpaper-derived, so every
        // user sees the same Invois colors regardless of their phone.
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.brandAccent,
          surface: Colors.white,
          error: AppColors.danger(Brightness.light),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: inputTheme,
        chipTheme: chipTheme(Brightness.light),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brandAccent, brightness: Brightness.dark).copyWith(
          primary: AppColors.brandAccent,
          secondary: AppColors.brandAccent,
          error: AppColors.danger(Brightness.dark),
        ),
        cardTheme: const CardThemeData(
          color: AppColors.darkSurface,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: inputTheme.copyWith(
          fillColor: AppColors.slate800,
        ),
        chipTheme: chipTheme(Brightness.dark),
      ),
      home: const MainTabView(),
    );
  }
}
