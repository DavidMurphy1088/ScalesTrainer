import SwiftUI

//func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//    //ScalesModel.staticInstance = ScalesModel()
//    //PianoKeyboardModel.staticInstance = PianoKeyboardModel()
//    return true
//}

@main
struct ScalesTrainerApp: App {
    @State private var selectedTab = 0
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                ScalesView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(0)
                SpriteKitAudioView()
                    .tabItem {
                        Label("Game", systemImage: "house")
                    }
//                MetronomeView()
//                    .tabItem {
//                        Label("Metronome", systemImage: "house")
//                    }
//
//                StaveView()
//                    .tabItem {
//                        Label("Notes", systemImage: "house")
//                    }
//                    .tag(1)
                CallibrationView()
                    .tabItem {
                        Label("Calibration", systemImage: "gear")
                    }
                    .tag(2)
                LogView()
                    .tabItem {
                        Label("Log", systemImage: "gear")
                    }
                    .tag(3)
            }
            .onAppear() {
                if ScalesModel.shared.requiredStartAmplitude == nil {
                    self.selectedTab = 2
                }
            }
        }
    }
}
