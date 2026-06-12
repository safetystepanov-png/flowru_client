import UIKit
import Flutter
import FirebaseMessaging
import UserNotifications

class FlowNativePushState {
  static var apnsStatus: String = "native-not-started"
}

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self

    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    let prefix = String(token.prefix(24))

    FlowNativePushState.apnsStatus = "native-apns-ok-\(prefix)"
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

    FlowNativePushState.apnsStatus = "native-apns-fail-\(String(safe.prefix(120)))"
  }
}