import UIKit
import Flutter
import GoogleMaps
import Firebase
import flutter_downloader
import FBSDKCoreKit
import FBSDKLoginKit
import TikTokBusinessSDK


@main
@objc class AppDelegate: FlutterAppDelegate {
  private let providerAppChannel = "com.sixamtech.demandium.user/provider_app"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
     FirebaseApp.configure()
     GMSServices.provideAPIKey("AIzaSyA3XZOic8YppjJMQwvFVa1y5DhQAdStRtA")
    GeneratedPluginRegistrant.register(with: self)
      FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: providerAppChannel,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "openProviderApp" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let args = call.arguments as? [String: Any]
        let appStoreId = args?["appStoreId"] as? String ?? "6504851611"
        let urlSchemes = args?["urlSchemes"] as? [String] ?? []
        let appStoreUrl = args?["appStoreUrl"] as? String
          ?? "https://apps.apple.com/in/app/panun-kaergar-provider/id6504851611"
        self?.openProviderApp(
          urlSchemes: urlSchemes,
          appStoreId: appStoreId,
          appStoreUrl: appStoreUrl,
          result: result
        )
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func openProviderApp(
    urlSchemes: [String],
    appStoreId: String,
    appStoreUrl: String,
    result: @escaping FlutterResult
  ) {
    for scheme in urlSchemes {
      guard let url = URL(string: "\(scheme)://") else { continue }
      if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, options: [:]) { success in
          result(success)
        }
        return
      }
    }

    if let storeUrl = URL(string: "itms-apps://apps.apple.com/app/id\(appStoreId)") {
      UIApplication.shared.open(storeUrl, options: [:]) { success in
        if success {
          result(success)
          return
        }
        if let webUrl = URL(string: appStoreUrl) {
          UIApplication.shared.open(webUrl, options: [:], completionHandler: result)
        } else {
          result(false)
        }
      }
      return
    }

    result(false)
  }
}

private func registerPlugins(registry: FlutterPluginRegistry) {
    if (!registry.hasPlugin("FlutterDownloaderPlugin")) {
       FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!)
    }
}
