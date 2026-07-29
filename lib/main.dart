import 'package:dynamic_color/dynamic_color.dart';
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
            colorScheme: (lightDynamic ?? ColorScheme.fromSeed(seedColor: AppColors.primary)).copyWith(
              primary: lightDynamic?.primary ?? AppColors.primary,
              secondary: lightDynamic?.secondary ?? AppColors.brandAccent,
              surface: lightDynamic?.surface ?? Colors.white,
              error: lightDynamic?.error ?? AppColors.danger(Brightness.light),
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
                    ColorScheme.fromSeed(seedColor: AppColors.brandAccent, brightness: Brightness.dark))
                .copyWith(
              primary: darkDynamic?.primary ?? AppColors.brandAccent,
              secondary: darkDynamic?.secondary ?? AppColors.brandAccent,
              error: darkDynamic?.error ?? AppColors.danger(Brightness.dark),
            ),
            cardTheme: const CardThemeData(
              surfaceTintColor: Colors.transparent,
            ),
            inputDecorationTheme: inputTheme.copyWith(
              fillColor: AppColors.slate800,
            ),
          ),
          home: const MainTabView(),
        );
      },
    );
  }
}
