import SwiftUI

@main

//class AppDelegate: UIResponder, UIApplicationDelegate {
//    var window: UIWindow?
////    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
////        return .portrait
////    }
//}

struct ScalesTrainerApp: App {
    @State private var selectedTab = Settings.shared.amplitudeFilter == 0 ? 2 : 0
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
//                PracticeJournal()
//                    .tabItem {
//                        Label("TEST", systemImage: "music.note.list")
//                    }
//                    .tag(0)

                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(0)

//                ScalesView(activityMode: ActivityMode(name: "All", implemented: true, imageName: "", showStaff: false, showFingers: true))
//                    .tabItem {
//                        Label("TEST", systemImage: "music.note.list")
//                    }
//                    .tag(1)
                
                CallibrationView()
                    .tabItem {
                        Label("Calibration", systemImage: "lines.measurement.vertical")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(3)

                LogView()
                    .tabItem {
                        Label("Log", systemImage: "book.pages")
                    }
                    .tag(4)
                    
                //                SpriteKitAudioView()
                //                    .tabItem {
                //                        Label("Game", systemImage: "house")
                //                    }
                }
                //.border(Color.red)
                .onAppear() {
//                    if ScalesModel.shared.requiredStartAmplitude == nil {
//                        self.selectedTab = 2
//                    }
                }
        }
    }
}
