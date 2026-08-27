import Flutter
import UIKit

/**
 * Honest iOS Assistive & Switch Control Bridge (§2).
 * Provides deep-linking to iOS Switch Control recipes and queries UIAccessibility status.
 */
class SwitchControlBridge: NSObject {
    static func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(
            name: "com.example.auto_clicker/ios_assistive",
            binaryMessenger: messenger
        )
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "isSwitchControlRunning":
                result(UIAccessibility.isSwitchControlRunning)
            case "openSwitchControlSettings":
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
