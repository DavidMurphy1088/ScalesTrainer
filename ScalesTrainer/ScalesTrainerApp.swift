import SwiftUI

@main

//class AppDelegate: UIResponder, UIApplicationDelegate {
//    var window: UIWindow?
////    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
////        return .portrait
////    }
//}

struct ScalesTrainerApp: App {
    @State private var selectedTab = 0
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                ScalesView(activityMode: ActivityMode(name: "All", imageName: "", showStaff: false, showFingers: true))
                    .tabItem {
                        Label("Scales", systemImage: "music.note.list")
                    }
                    .tag(0)
                
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(0)

                CallibrationView()
                    .tabItem {
                        Label("Calibration", systemImage: "gear")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }

//                CallibrationViewOld()
//                    .tabItem {
//                        Label("OldCalibration", systemImage: "gear")
//                    }
//                    .tag(2)
                LogView()
                    .tabItem {
                        Label("Log", systemImage: "gear")
                    }
                    .tag(3)
                
//                SpriteKitAudioView()
//                    .tabItem {
//                        Label("Game", systemImage: "house")
//                    }
            }
            .onAppear() {
                let shared = ScalesModel.shared
                if ScalesModel.shared.requiredStartAmplitude == nil {
                    self.selectedTab = 2
                }
            }
        }
    }
}
