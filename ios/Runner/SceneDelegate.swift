import UIKit
import Flutter
import app_links

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  private let pushChannelName = "ru.flowru.client/push_native"

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    setupPushNativeChannel()
    self.scene(scene, openURLContexts: connectionOptions.urlContexts)
    for activity in connectionOptions.userActivities {
      self.scene(scene, continue: activity)
    }
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
      AppLinks.shared.handleLink(url: context.url)
    }
  }

  func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    if let url = userActivity.webpageURL {
      AppLinks.shared.handleLink(url: url)
    }
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