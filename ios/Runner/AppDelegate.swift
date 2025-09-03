import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    GMSServices.provideAPIKey("AIzaSyBF6gIU35hd51XwJrZOh4j8x9Hcr-WmPt0")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
