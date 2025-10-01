import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('ukitar.external_launcher');

Future<bool> openExternalUrl(String url) async {
  try {
    final bool? opened = await _channel.invokeMethod<bool>('openUrl', url);
    return opened ?? false;
  } on PlatformException {
    return false;
  }
}
