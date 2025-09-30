# Ukitar

Ukitar is a Flutter-based guitar practice companion that performs pitch
detection to help you tune and practise chords.

## Requirements

- Flutter 3.6 or newer
- Dart SDK 3.6 or newer (bundled with Flutter)
- An Android device running Android 6.0 (API 23) or newer for on-device testing

## Running the app on Android

1. Ensure that you have installed the [Android platform
   dependencies](https://docs.flutter.dev/get-started/install) for Flutter and
   enabled USB debugging on your device.
2. Connect your device via USB (or ensure that it is discoverable over Wi-Fi).
3. Run `flutter devices` to verify that Flutter can detect your Android device.
4. Launch the application on the device with `flutter run -d <device-id>`.

### Microphone permission

Ukitar relies on live audio input to provide chord and tuning feedback. On
Android you will be prompted to grant microphone access the first time you open
the app. If you previously denied the permission, you can enable it manually via
**Settings → Apps → Ukitar → Permissions**.

## Additional resources

- [Flutter documentation](https://docs.flutter.dev/)
- [Flutter cookbook](https://docs.flutter.dev/cookbook)
