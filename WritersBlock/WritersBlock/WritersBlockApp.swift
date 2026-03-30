import SwiftUI

@main
struct WritersBlockApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("isDarkMode") private var isDarkMode = false

    @State private var storeManager = StoreManager()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootNavigationView(store: .shared, storeManager: storeManager)
                if showSplash {
                    SplashView(isShowing: $showSplash)
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .task {
                // Pre-load WordValidator while the splash screen shows
                await Task.detached(priority: .background) {
                    _ = WordValidator.shared
                }.value
            }
        }
    }
}
