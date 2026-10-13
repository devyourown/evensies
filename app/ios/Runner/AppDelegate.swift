import Flutter
import UIKit
import UserNotifications
import Vision

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
    // App icon badge = unread activity (docs/API.md, Unread activity): `set` with the count, 0 clears it.
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
    // Receipt scan (docs/API.md, Receipts): the photo's text lines, read on the phone with Apple Vision. `recognize`
    // {path} → [{text, left, top, right, bottom}] in pixels of the upright image, origin top left.
    let ocr = FlutterMethodChannel(
      name: "evensies/ocr", binaryMessenger: engineBridge.applicationRegistrar.messenger())
    ocr.setMethodCallHandler { call, result in
      guard call.method == "recognize", let path = (call.arguments as? [String: Any])?["path"] as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let lines = Result { try AppDelegate.recognizeLines(URL(fileURLWithPath: path)) }
        DispatchQueue.main.async {
          switch lines {
          case .success(let l): result(l)
          case .failure(let e): result(FlutterError(code: "OCR", message: e.localizedDescription, details: nil))
          }
        }
      }
    }
  }

  private static func recognizeLines(_ url: URL) throws -> [[String: Any]] {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
    else { throw CocoaError(.fileReadCorruptFile) }
    let raw = props[kCGImagePropertyOrientation] as? UInt32 ?? 1
    var width = (props[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue ?? 1
    var height = (props[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue ?? 1
    if raw >= 5 { swap(&width, &height) }  // EXIF 5–8: turned by 90°
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false  // prices and codes, not words
    try VNImageRequestHandler(url: url, orientation: CGImagePropertyOrientation(rawValue: raw) ?? .up)
      .perform([request])
    return (request.results ?? []).compactMap { o in
      guard let text = o.topCandidates(1).first?.string else { return nil }
      let b = o.boundingBox  // normalized, origin bottom left
      return [
        "text": text, "left": b.minX * width, "right": b.maxX * width,
        "top": (1 - b.maxY) * height, "bottom": (1 - b.minY) * height,
      ]
    }
  }
}
