import 'dart:convert';
import 'package:http/http.dart' as http;

class UpdateInfo {
  final String tag;
  final String releasePageUrl;
  final String? apkDownloadUrl;
  UpdateInfo({required this.tag, required this.releasePageUrl, this.apkDownloadUrl});
}

/// Checks GitHub Releases for a newer version than what's currently installed.
///
/// Works with release.yml, which only tags an official release as
/// "vMAJOR.MINOR.PATCH" (matching pubspec.yaml's version name) when that
/// tag is pushed — see the repo's `.github/workflows/release.yml`.
/// This compares the release tag against the running app's own version
/// name (from PackageInfo.version) using plain semantic-version comparison.
class UpdateCheckService {
  /// IMPORTANT: replace with your actual "owner/repo", e.g. "jkamau/invois".
  static const String repoSlug = 'tilelvis/invois';

  static Future<UpdateInfo?> checkForUpdate({required String currentVersion}) async {
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

      final latestVersion = tagName.startsWith('v') ? tagName.substring(1) : tagName;
      if (!_isNewer(latestVersion, currentVersion)) return null;

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

  /// Compares two "MAJOR.MINOR.PATCH"-style version strings. Returns true
  /// if [candidate] is strictly newer than [current]. Malformed or missing
  /// parts are treated as 0, so this never throws on unexpected input.
  static bool _isNewer(String candidate, String current) {
    final c = _parseVersion(candidate);
    final b = _parseVersion(current);
    for (var i = 0; i < 3; i++) {
      if (c[i] != b[i]) return c[i] > b[i];
    }
    return false;
  }

  static List<int> _parseVersion(String version) {
    final parts = version.split('.');
    return List.generate(3, (i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0);
  }
}
