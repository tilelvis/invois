import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/invoice_form_view.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invois - Kenya Invoicing App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // High-contrast outdoor-optimized theme
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF005A36), // Primary Safaricom green
          primary: const Color(0xFF005A36),
          secondary: const Color(0xFF10B981), // Light green / success paid accent
          surface: Colors.white,
          error: Colors.red[800]!,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: const InputDecorationTheme(
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
        ),
      ),
      home: const InvoiceFormView(),
    );
  }
}
