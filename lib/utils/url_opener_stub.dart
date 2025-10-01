import 'package:url_launcher/url_launcher.dart';

Future<bool> openExternalUrl(String url) async {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null) {
    return false;
  }

  // Try launching outside the app when possible (e.g., dedicated app or browser).
  if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    return true;
  }

  // Fallback to the platform default behaviour.
  return launchUrl(uri, mode: LaunchMode.platformDefault);
}
