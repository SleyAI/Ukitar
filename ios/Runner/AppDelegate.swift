import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "ukitar.external_launcher",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { call, result in
        if call.method == "openUrl" {
          guard let urlString = call.arguments as? String,
                let url = URL(string: urlString) else {
            result(FlutterError(code: "INVALID_URL", message: "URL was nil or malformed", details: nil))
            return
          }

          DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(url) {
              UIApplication.shared.open(url, options: [:]) { success in
                result(success)
              }
            } else {
              result(false)
            }
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
