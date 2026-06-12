import UIKit
import Flutter

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  private let pushChannelName = "ru.flowru.client/push_native"

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    setupPushNativeChannel()
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    setupPushNativeChannel()
  }

  private func setupPushNativeChannel() {
    guard let flutterViewController = window?.rootViewController as? FlutterViewController else {
      FlowNativePushState.apnsStatus = "native-channel-no-flutter-root"
      return
    }

    let channel = FlutterMethodChannel(
      name: pushChannelName,
      binaryMessenger: flutterViewController.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      if call.method == "registerForRemoteNotifications" {
        FlowNativePushState.apnsStatus = "native-register-called"

        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }

        result(FlowNativePushState.apnsStatus)
        return
      }

      if call.method == "getApnsStatus" {
        result(FlowNativePushState.apnsStatus)
        return
      }

      result(FlutterMethodNotImplemented)
    }
  }
}