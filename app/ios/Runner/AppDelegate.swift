import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // App icon badge = unread activity (docs/API.md 읽지 않은 활동): `set` with the count, 0 clears it.
    let badge = FlutterMethodChannel(
      name: "evensies/badge", binaryMessenger: engineBridge.applicationRegistrar.messenger())
    badge.setMethodCallHandler { call, result in
      guard call.method == "set", let count = call.arguments as? Int else {
        result(FlutterMethodNotImplemented)
        return
      }
      if #available(iOS 16.0, *) {
        UNUserNotificationCenter.current().setBadgeCount(max(count, 0)) { _ in result(nil) }
      } else {
        UIApplication.shared.applicationIconBadgeNumber = max(count, 0)
        result(nil)
      }
    }
  }
}
