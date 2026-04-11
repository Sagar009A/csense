import Flutter
import UIKit
import google_mobile_ads

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register native ad factory (matches Android "mediumNativeAd" factory id)
    let factory = MediumNativeAdFactory()
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      self,
      factoryId: "mediumNativeAd",
      nativeAdFactory: factory
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
