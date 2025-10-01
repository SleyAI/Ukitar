# Ukitar

Ukitar is a Flutter learning companion that guides new ukulele players through
beginner-friendly chords while providing real-time microphone feedback. The app
combines a curated lesson path with on-device pitch detection so that every
strum helps you unlock the next skill.

## Features

- **Guided chord progression** – Step-by-step beginner course that unlocks new
  chords after you master the previous one with clean repetitions.
- **Interactive practice screen** – Visual chord diagrams, finger placement tips
  and progress tracking tailored to the currently selected chord.
- **Real-time listening feedback** – Microphone-based pitch detection validates
  every string, highlights successful matches and tracks repetition goals.
- **Permission handling assistance** – In-app prompts help learners grant the
  microphone access required for listening mode.
- **Reset and retry controls** – Quickly restart an attempt or stop listening to
  adjust your playing before the next strum.

## Technologies & Libraries

- [Flutter](https://flutter.dev/) with Material 3 styling for the UI layer.
- [Dart](https://dart.dev/) for cross-platform application logic.
- [`provider`](https://pub.dev/packages/provider) for state management across the
  app.
- [`flutter_fft`](https://pub.dev/packages/flutter_fft) to read microphone input
  and detect dominant frequencies in real time.
- [`permission_handler`](https://pub.dev/packages/permission_handler) to request
  and manage microphone permissions on device.

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
