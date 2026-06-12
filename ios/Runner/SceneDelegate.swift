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
    guard let windowScene = scene as? UIWindowScene else {
      FlowNativePushState.apnsStatus = "native-scene-no-window-scene"
      return
    }

    let flutterViewController = FlutterViewController()
    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = flutterViewController
    self.window = window
    window.makeKeyAndVisible()

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