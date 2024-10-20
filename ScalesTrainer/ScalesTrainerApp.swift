import SwiftUI
import AudioKit
import AVFoundation
import SwiftUI
import Foundation

enum LaunchScreenStep {
    case firstStep
    case secondStep
    case finished
}

public enum RequestStatus {
    case success
    case waiting
    case failed
}

final class LaunchScreenStateManager: ObservableObject {
    @MainActor @Published private(set) var state: LaunchScreenStep = .firstStep

    @MainActor func dismiss() {
        Task {
            state = .secondStep
            sleep(1)
            self.state = .finished
        }
    }
}

class Opacity : ObservableObject {
    @Published var imageOpacity: Double = 0.0
    var launchTimeSecs:Double
    var timer:Timer?
    var ticksPerSec = 30.0
    var duration = 0.0
    
    init(launchTimeSecs:Double) {
        self.launchTimeSecs = launchTimeSecs
        let timeInterval = 1.0 / ticksPerSec
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
            DispatchQueue.main.async {
                let opacity = sin((self.duration * Double.pi * 1.0) / self.launchTimeSecs)
                self.imageOpacity = opacity
                if self.duration >= self.launchTimeSecs {
                    self.timer?.invalidate()
                }
                self.duration += timeInterval
            }
        }
    }
}

struct LaunchScreenView: View {
    static var staticId = 0
    var id = 0
    @ObservedObject var opacity:Opacity
    @State var durationSeconds:Double
    @EnvironmentObject private var launchScreenState: LaunchScreenStateManager // Mark 1
    
    init(launchTimeSecs:Double) {
        self.opacity = Opacity(launchTimeSecs: launchTimeSecs)
        self.durationSeconds = launchTimeSecs
        self.id = LaunchScreenView.staticId
        LaunchScreenView.staticId += 1
    }

    func appVersion() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return "\(appVersion).\(buildNumber)"
    }
        
    @ViewBuilder
    private var image: some View {  // Mark 3
        GeometryReader { geo in
            //hack: for some reason there are 2 instances of LaunchScreenView. The first starts showing too early ??
            //if id == 1 {
                VStack {
                    ///Image causes title to be truncated on phone
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image("trinity")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: geo.size.width * 0.40)
                                    .cornerRadius(10) // Adjust the radius value to your preference
                                    .opacity(self.opacity.imageOpacity)
                            Spacer()
                        }
                        Spacer()
                    }
                    VStack(alignment: .center) {
                        Text("Scales Academy").font(.title)
                        Text("")
                        Text("© 2024 Musicmaster Education LLC.")//.font(.title3)
                        //.position(x: geo.size.width * 0.5, y: geo.size.height * 0.85)
                        //.opacity(self.opacity.imageOpacity)
                        Text("Version \(appVersion())")
                        Text("")
                        Text("")
                    }
                }
            //}
        }
    }
    
    var body: some View {
        ZStack {
            image
        }
    }
}

struct DeveloperView: View {
    let scalesModel = ScalesModel.shared
    @State var showingTapData = false

    var body: some View {
        VStack {
            Spacer()
//            Button("READ_TEST_DATA") {
//                scalesModel.setRunningProcess(.recordScaleWithFileData)
//            }.padding()
            //if scalesModel.tapHandlerEventSetPublished  {

            Button("Show Tap Data") {
                //self.showScaleStart()
                showingTapData = true
            }
                
            //}
//            if scalesModel.recordedTapsFileName != nil {
//                Spacer()
//                if MFMailComposeViewController.canSendMail() {
//                    Button("Send Tap Data") {
//                        activeSheet = .emailRecording
//                    }
//                }
//                else {
//                    Text("No mail")
//                }
//            }
            Spacer()
        }
        .sheet(isPresented: $showingTapData) {
            TapDataView(keyboardModel: PianoKeyboardModel.sharedRH)
        }
    }
}

class TabSelectionManager: ObservableObject {
    @Published var selectedTab: Int = 0
    init() {
        nextNavigationTab()
    }
    
    func nextNavigationTab() {
        if Settings.shared.settingsExists() {
            if Settings.shared.calibrationIsSet() {
                if Settings.shared.isDeveloperMode() {
                    //ScalesModel.shared.setScaleByRootAndType(scaleRoot: ScaleRoot(name: "F"), scaleType: .major, scaleMotion: .similarMotion, minTempo: 50, octaves: 1, hands: [0], ctx: "App Start")
                    ScalesModel.shared.setScaleByRootAndType(scaleRoot: ScaleRoot(name: "C"), scaleType: .brokenChordMajor, scaleMotion: .similarMotion, minTempo: 42, octaves: 1, hands: [0], ctx: "App Start")
                    selectedTab = 0
                }
                else {
                    selectedTab = 1
                }
            }
            else{
                selectedTab = 4
            }
        }
        else {
            selectedTab = 2
        }
    }
}

@main
struct ScalesTrainerApp: App {
    @StateObject private var tabSelectionManager = TabSelectionManager()
    @StateObject var launchScreenState = LaunchScreenStateManager()
    var launchTimeSecs = 4.5
    
    init() {
        #if os(iOS)
            do {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch let err {
                Logger.shared.reportError(AVAudioSession.sharedInstance(), err.localizedDescription)
            }
        #endif
    }
    
    static func runningInXcode1() -> Bool {
        let running = ProcessInfo.processInfo.environment["RUNNING_FROM_XCODE"] != nil
        return running
        //return false
    }
    
    func getDataLoadedStatus() -> RequestStatus {
        return .waiting //self.exampleData.dataStatus
    }
    
    var body: some Scene {
        WindowGroup {
            VStack {
                //if launchScreenState.state == .finished || ScalesTrainerApp.runningInXcode() {
                if launchScreenState.state == .finished || Settings.shared.isDeveloperMode() {
                    MainContentView()
                }
                else {
                    if launchScreenState.state != .finished {
                        LaunchScreenView(launchTimeSecs: 4.5)
                    }
                }
            }
            .task {
                DispatchQueue.main.asyncAfter(deadline: .now() + launchTimeSecs) {
                    self.launchScreenState.dismiss()
                }
            }
        }
    }

    func MainContentView() -> some View {

        TabView(selection: $tabSelectionManager.selectedTab) {
            if Settings.shared.isDeveloperMode() {
                //MIDIView()
                //PracticeChartView(rows: 10, columns: 3)
                //HomeView()
                ScalesView(initialRunProcess: nil, practiceChartCell: nil)
                //TestView()
                //FFTContentView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(0)
            }
            
            HomeView()
                .tabItem {
                    Label(NSLocalizedString("Home", comment: "Menu"), systemImage: "house")
                }
                .tag(1)
            GradeAndBoard()
                .tabItem {
                    //Label("Board and Grade", systemImage: "arrowshape.forward.circle")
                    Label(NSLocalizedString("Grade", comment: "Menu"), systemImage: "arrowshape.forward.circle")
                }
                .tag(2)
                .environmentObject(tabSelectionManager)
            SettingsView()
                .tabItem {
                    Label(NSLocalizedString("Settings", comment: "Menu"), systemImage: "gear")
                }
                .tag(3)
                .environmentObject(tabSelectionManager)
            
            if Settings.shared.isDeveloperMode() {
                ScalesLibraryView()
                    .tabItem {
                        Label(NSLocalizedString("ScaleLibrary", comment: "Menu"), systemImage: "book")
                    }
                    .tag(4)
                    .environmentObject(tabSelectionManager)
            }
            
            if Settings.shared.isDeveloperMode() {
                CalibrationView()
                    .tabItem {
                        Label("Calibration", systemImage: "lines.measurement.vertical")
                    }
                    .tag(5)
                    .environmentObject(tabSelectionManager)
            }
            
            if Settings.shared.isDeveloperMode()  {
                // DeveloperView().commonFrameStyle()
                ScalesLibraryView()
                    .tabItem {
                        Label("ScaleLibrary", systemImage: "book.pages")
                    }
                    .tag(6)
                    .environmentObject(tabSelectionManager)

                LogView()
                    .tabItem {
                        Label("Log", systemImage: "book.pages")
                    }
                    .tag(7)
                    .environmentObject(tabSelectionManager)
                DeveloperView()
                    .tabItem {
                        Label("Dev", systemImage: "book.pages")
                    }
                    .tag(8)
                    .environmentObject(tabSelectionManager)
            }
        }
    }
}
