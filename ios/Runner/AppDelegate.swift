import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let automationChannel = FlutterMethodChannel(
      name: "com.example.auto_clicker/automation",
      binaryMessenger: controller.binaryMessenger
    )

    automationChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "isAccessibilityGranted":
        // iOS sandboxing prevents 3rd-party touch injection; return true for compatibility
        result(true)
      case "openAccessibilitySettings":
        if let url = URL(string: UIApplication.openSettingsURLString) {
          if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
          }
        }
        result(true)
      case "isOverlayGranted":
        result(true)
      case "openOverlaySettings":
        result(true)
      case "dispatchClick", "dispatchSwipe":
        // Simulated execution inside in-app sandbox
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    SwitchControlBridge.register(with: controller.binaryMessenger)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
