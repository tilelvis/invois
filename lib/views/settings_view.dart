import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../services/update_check_service.dart';
import '../widgets/app_design_system.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  String _version = '—';
  bool _checkingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = '${info.version} (build ${info.buildNumber})');
  }

  Future<void> _checkForUpdate() async {
    setState(() => _checkingUpdate = true);
    final info = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(info.buildNumber) ?? 0;
    final update = await UpdateCheckService.checkForUpdate(currentBuildNumber: currentBuild);
    if (!mounted) return;
    setState(() => _checkingUpdate = false);

    if (update == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You're on the latest version.")),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New version ${update.tag} available'),
        action: SnackBarAction(
          label: 'DOWNLOAD',
          onPressed: () => launchUrl(
            Uri.parse(update.apkDownloadUrl ?? update.releasePageUrl),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('APPEARANCE', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary(Theme.of(context).brightness), fontSize: 12)),
          ),
          SwitchListTile(
            title: const Text('Dark mode'),
            subtitle: const Text('Easier on the eyes in low light'),
            value: isDark,
            onChanged: (value) => ref.read(themeModeProvider.notifier).toggle(value),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('ABOUT', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary(Theme.of(context).brightness), fontSize: 12)),
          ),
          const ListTile(
            leading: Icon(Icons.receipt_long),
            title: Text('Invois'),
            subtitle: Text('Kenya invoicing app for contractors & informal-sector businesses'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: Text(_version),
          ),
          ListTile(
            leading: _checkingUpdate
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.system_update_outlined),
            title: const Text('Check for updates'),
            subtitle: const Text('Checks GitHub Releases for a newer build'),
            onTap: _checkingUpdate ? null : _checkForUpdate,
          ),
        ],
      ),
    );
  }
}
