import UIKit
import Flutter
import FirebaseMessaging
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private let pushChannelName = "ru.flowru.client/push_native"
  private var apnsStatus = "native-not-started"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self

    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: pushChannelName,
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else {
          result(FlutterError(code: "native_self_missing", message: "AppDelegate is missing", details: nil))
          return
        }

        if call.method == "registerForRemoteNotifications" {
          self.apnsStatus = "native-register-called"
          DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
          }
          result(self.apnsStatus)
          return
        }

        if call.method == "getApnsStatus" {
          result(self.apnsStatus)
          return
        }

        result(FlutterMethodNotImplemented)
      }
    } else {
      apnsStatus = "native-channel-no-root-controller"
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    let prefix = String(token.prefix(24))

    apnsStatus = "native-apns-ok-\(prefix)"
    Messaging.messaging().apnsToken = deviceToken

    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    let raw = error.localizedDescription
    let safe = raw
      .replacingOccurrences(of: " ", with: "_")
      .replacingOccurrences(of: "\n", with: "_")
      .replacingOccurrences(of: "\r", with: "_")

    apnsStatus = "native-apns-fail-\(String(safe.prefix(120)))"
  }
}