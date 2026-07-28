import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart';
import 'services/storage_service.dart';
import 'views/main_tab_view.dart';

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
        borderSide: BorderSide(color: Color(0xFF005A36), width: 2),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      filled: true,
      fillColor: Color(0xFFF8FAFC),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          title: 'Invois - Kenya Invoicing App',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            // Prefer the user's wallpaper-derived palette on Android 12+ (Material You),
            // falling back to our brand green when dynamic color isn't available.
            colorScheme: (lightDynamic ?? ColorScheme.fromSeed(seedColor: const Color(0xFF005A36))).copyWith(
              primary: lightDynamic?.primary ?? const Color(0xFF005A36),
              secondary: lightDynamic?.secondary ?? const Color(0xFF10B981),
              surface: lightDynamic?.surface ?? Colors.white,
              error: lightDynamic?.error ?? Colors.red[800]!,
            ),
            cardTheme: const CardThemeData(
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
            ),
            inputDecorationTheme: inputTheme,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: (darkDynamic ??
                    ColorScheme.fromSeed(seedColor: const Color(0xFF10B981), brightness: Brightness.dark))
                .copyWith(
              primary: darkDynamic?.primary ?? const Color(0xFF10B981),
              secondary: darkDynamic?.secondary ?? const Color(0xFF10B981),
              error: darkDynamic?.error ?? Colors.red[300]!,
            ),
            cardTheme: const CardThemeData(
              surfaceTintColor: Colors.transparent,
            ),
            inputDecorationTheme: inputTheme.copyWith(
              fillColor: const Color(0xFF1E1E1E),
            ),
          ),
          home: const MainTabView(),
        );
      },
    );
  }
}
