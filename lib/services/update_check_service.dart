import 'dart:convert';
import 'package:http/http.dart' as http;

class UpdateInfo {
  final String tag;
  final String releasePageUrl;
  final String? apkDownloadUrl;
  UpdateInfo({required this.tag, required this.releasePageUrl, this.apkDownloadUrl});
}

/// Checks GitHub Releases for a newer build than what's currently installed.
///
/// Works with the build-apk.yml workflow, which tags each release as
/// "v<versionName>-buildN" and attaches the APK — this compares N (the
/// GitHub Actions run number, always increasing) against the running app's
/// build number (from PackageInfo).
class UpdateCheckService {
  /// IMPORTANT: replace with your actual "owner/repo", e.g. "jkamau/invois".
  static const String repoSlug = 'tilelvis/invois';

  static Future<UpdateInfo?> checkForUpdate({required int currentBuildNumber}) async {
    if (repoSlug.startsWith('YOUR_GITHUB_USERNAME')) {
      // Not configured yet — silently skip rather than error out.
      return null;
    }
    try {
      final uri = Uri.parse('https://api.github.com/repos/$repoSlug/releases/latest');
      final response = await http
          .get(uri, headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String?;
      final htmlUrl = data['html_url'] as String?;
      if (tagName == null || htmlUrl == null) return null;

      final match = RegExp(r'build(\d+)').firstMatch(tagName);
      if (match == null) return null;
      final latestBuildNumber = int.tryParse(match.group(1)!);
      if (latestBuildNumber == null || latestBuildNumber <= currentBuildNumber) return null;

      String? apkUrl;
      final assets = data['assets'] as List<dynamic>?;
      if (assets != null) {
        for (final asset in assets) {
          final name = asset['name'] as String?;
          if (name != null && name.endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String?;
            break;
          }
        }
      }

      return UpdateInfo(tag: tagName, releasePageUrl: htmlUrl, apkDownloadUrl: apkUrl);
    } catch (_) {
      // Network errors, rate limits, etc. — fail silently, this is a "nice
      // to have" check, not something that should ever block app usage.
      return null;
    }
  }
}
