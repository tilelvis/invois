import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('APPEARANCE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black45, fontSize: 12)),
          ),
          SwitchListTile(
            title: const Text('Dark mode'),
            subtitle: const Text('Easier on the eyes in low light'),
            value: isDark,
            onChanged: (value) => ref.read(themeModeProvider.notifier).toggle(value),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('ABOUT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black45, fontSize: 12)),
          ),
          const ListTile(
            leading: Icon(Icons.receipt_long),
            title: Text('Invois'),
            subtitle: Text('Kenya invoicing app for contractors & informal-sector businesses'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0+1'),
          ),
        ],
      ),
    );
  }
}
