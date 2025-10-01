import 'package:url_launcher/url_launcher.dart';

Future<bool> openExternalUrl(String url) async {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null) {
    return false;
  }

  // Prefer opening the link inside an in-app browser sheet when available.
  if (await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
    return true;
  }

  // Fallback to the platform default behaviour.
  if (await launchUrl(uri, mode: LaunchMode.platformDefault)) {
    return true;
  }

  // Finally, try launching outside the app (e.g., dedicated app or browser).
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
