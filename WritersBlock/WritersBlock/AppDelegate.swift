import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let isDark = UITraitCollection.current.userInterfaceStyle == .dark
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { $0.backgroundColor = isDark
                ? UIColor(red: 0.047, green: 0.047, blue: 0.078, alpha: 1)
                : UIColor(red: 1.000, green: 0.984, blue: 0.961, alpha: 1)
            }
        return true
    }

    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
}
