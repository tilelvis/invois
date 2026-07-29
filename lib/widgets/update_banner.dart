import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_check_service.dart';
import 'app_design_system.dart';

const _dismissedTagPrefsKey = 'invois_dismissed_update_tag';

/// Shows a slim banner at the top of the screen when a newer build is
/// published to GitHub Releases than the one currently installed.
/// Silently does nothing if there's no update, no network, or the user
/// already dismissed this specific version.
class UpdateBanner extends StatefulWidget {
  const UpdateBanner({super.key});

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  UpdateInfo? _update;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final update = await UpdateCheckService.checkForUpdate(currentVersion: info.version);

      if (update != null) {
        final prefs = await SharedPreferences.getInstance();
        final dismissedTag = prefs.getString(_dismissedTagPrefsKey);
        if (dismissedTag == update.tag) {
          if (mounted) setState(() => _checked = true);
          return; // already dismissed this version
        }
      }

      if (mounted) {
        setState(() {
          _update = update;
          _checked = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checked = true);
    }
  }

  Future<void> _dismiss() async {
    if (_update != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dismissedTagPrefsKey, _update!.tag);
    }
    setState(() => _update = null);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || _update == null) return const SizedBox.shrink();

    return Material(
      color: AppColors.primary,
      child: InkWell(
        onTap: () => launchUrl(
          Uri.parse(_update!.apkDownloadUrl ?? _update!.releasePageUrl),
          mode: LaunchMode.externalApplication,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.system_update, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'A new version (${_update!.tag}) is available — tap to download',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                onPressed: _dismiss,
                tooltip: 'Dismiss',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
