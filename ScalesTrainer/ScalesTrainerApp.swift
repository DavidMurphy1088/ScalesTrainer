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
            TapDataView(keyboardModel: PianoKeyboardModel.sharedRightHand)
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
                if ScalesTrainerApp.runningInXcode() {
                    //ScalesModel.shared.setScale(scale: Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .arpeggioDiminishedSeventh, octaves: 2, hand: 0))
//                    ScalesModel.shared.setScale(scale: Scale(scaleRoot: ScaleRoot(name: "C"),
//                                                             scaleType: .contraryMotion,
//                                                             octaves: 1, hand: 2,
//                                                             minTempo: 60, dynamicType: .mf, articulationType: .legato))
                    ScalesModel.shared.setScale(scale: Scale(scaleRoot: ScaleRoot(name: "C"),
                                                             scaleType: .major,
                                                             scaleMotion: .parallelMotion,
                                                             octaves: 1, hand: 1,
                                                             minTempo: 90, dynamicType: .mf, articulationType: .legato))
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
                print(err)
            }
        #endif
    }
    
    static func runningInXcode() -> Bool {
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
                if launchScreenState.state == .finished || ScalesTrainerApp.runningInXcode() {
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
            if ScalesTrainerApp.runningInXcode() {
                //MIDIView()
                //PracticeChartView(rows: 10, columns: 3)
                //SpinWheelView(practiceJournal: PracticeJournal.shared!)
                ScalesView()
                //TestView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(0)
            }
            
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(1)
            GradeAndBoard()
                .tabItem {
                    //Label("Board and Grade", systemImage: "arrowshape.forward.circle")
                    Label("Grade", systemImage: "arrowshape.forward.circle")
                }
                .tag(2)
                .environmentObject(tabSelectionManager)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
                .environmentObject(tabSelectionManager)
            
            if Settings.shared.developerModeOn {
                CalibrationView()
                    .tabItem {
                        Label("Calibration", systemImage: "lines.measurement.vertical")
                    }
                    .tag(4)
                    .environmentObject(tabSelectionManager)
            }
            
            if Settings.shared.developerModeOn  {
                // DeveloperView().commonFrameStyle()
                PickAnyScaleView()
                    .tabItem {
                        Label("PickScale", systemImage: "book.pages")
                    }
                    .tag(5)
                    .environmentObject(tabSelectionManager)

                LogView()
                    .tabItem {
                        Label("Log", systemImage: "book.pages")
                    }
                    .tag(6)
                    .environmentObject(tabSelectionManager)
                DeveloperView()
                    .tabItem {
                        Label("Dev", systemImage: "book.pages")
                    }
                    .tag(7)
                    .environmentObject(tabSelectionManager)
            }
        }
    }
}
