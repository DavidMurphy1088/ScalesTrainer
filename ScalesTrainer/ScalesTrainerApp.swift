import SwiftUI
import AudioKit
import AVFoundation
import SwiftUI
import Foundation
import StoreKit

import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import UIKit

enum LaunchScreenStep {
    case firstStep
    //case secondStep
    case finished
}

final class LaunchScreenStateManager: ObservableObject {
    @MainActor @Published private(set) var state: LaunchScreenStep = .firstStep
    @MainActor func dismiss() {
        Task {
            //state = .secondStep
            //sleep(1)
            self.state = .finished
        }
    }
}

struct LaunchScreenView: View {
    @EnvironmentObject private var launchScreenState: LaunchScreenStateManager // Mark 1

    func appVersion() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return "\(appVersion).\(buildNumber)"
    }
        
    func getImageSize(geo: GeometryProxy) -> Double {
        let imageSize:Double
        if UIDevice.current.userInterfaceIdiom == .phone {
            imageSize = min(geo.size.width, geo.size.height) * 0.80
        }
        else {
            imageSize = min(geo.size.width, geo.size.height) * 0.60
        }
        return imageSize
    }
    
    var body: some View {
        VStack {
            GeometryReader { geo in
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image("figma_logo_vertical")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: getImageSize(geo: geo))
                        Spacer()
                    }
                    VStack(alignment: .center) {
                        Text("© 2025 Musicmaster Education LLC.")
                        Text("Version \(appVersion())")
                    }
                    Spacer()
                }
            }
            .background(Figma.background)
        }
    }
}

struct DeveloperView: View {
    let scalesModel = ScalesModel.shared
    @State var showingTapData = false
    let email = "Fred1@gmail.com"
    @State private var password = "Password1"
    @State private var isLoggedIn = false
    @State var status = ""
    let logger = AppLogger.shared
    @State var ctr = 0
    let firebase = Firebase.shared
    
    var body: some View {
        VStack {
            Spacer()

            Button("Firebase Signin") {
//                firebase.signIn(email: email, pwd: password)
            }
            Spacer()
            
            Button(action: {
                //firebase.writeDataToRealtimeDatabase(key: "TESTVIEW", jsonString: "FRED", callback: nil)
            }) {
                Text("Firebase Write")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Spacer()
            
            Text(status)
            
            Spacer()
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
        .onAppear() {
            status = "Firebase not connected"
        }
        .sheet(isPresented: $showingTapData) {
            TapDataView(keyboardModel: PianoKeyboardModel.sharedRH)
        }
    }
}


class AppDelegate: NSObject, UIApplicationDelegate {
    var orientationLock: UIInterfaceOrientationMask = UIInterfaceOrientationMask.landscape
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        
#if targetEnvironment(simulator)
        ///Simulator asks for password every time even though its signed in with Apple ID. By design for IAP purchasing... :(
        ///Code to run on the Simulator
        AppLogger.shared.log(self, "Running on the Simulator, will not load IAP licenses")
#else
        SKPaymentQueue.default().add(LicenceManager.shared) ///Do this as early as possible so manager is a queue observer
        LicenceManager.shared.verifyStoredSubscriptionReceipt(ctx: "App starting") ///Get the current validity of any locally stored subscription receipt
        LicenceManager.shared.requestProducts() ///Get products
        ///LicenceManager.shared.restoreTransactions() ///No need - the last subscription receipt received is stored locally. If not (e.g. nmew device) user does 'Restore Subscriptions'
#endif
        FirebaseApp.configure()
        if !Settings.shared.isDeveloperModeOn() {
            LicenceManager.shared.getFreeLicenses()
        }
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        AppLogger.shared.log(self, "Version.Build \(appVersion).\(buildNumber)")
        
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        var statusMsg = ""
        switch status {
        case .authorized:
            statusMsg = "The user has previously granted access to the microphone."
        case .notDetermined:
            statusMsg = "The user has not yet been asked to grant microphone access."
        case .denied:
            statusMsg = "The user has previously denied access."
        case .restricted:
            statusMsg = "The user can't grant access due to restrictions."
        @unknown default:
            statusMsg = "unknown \(status)"
        }
        AppLogger.shared.log(self, "Microphone access:\(statusMsg))")
        return true
    }
    
//    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
////        if UIDevice.current.userInterfaceIdiom == .phone {
////            //return [.portrait]
////            return [.portrait, .landscapeLeft, .landscapeRight]
////        } else {
////            return [.portrait, .landscapeLeft, .landscapeRight] // Allow both on iPad
////        }
//
//        //return orientationLock
//        return UIInterfaceOrientationMask.landscape
//    }
}

///------------------------------------------------------------

class ViewManager: ObservableObject {
    static let TAB_WELCOME = 100
    static let TAB_ACTIVITES = 10
    static let TAB_USERS = 20

    static var shared = ViewManager()
    @Published var selectedTab: Int = 0
    @Published var publishedUser: User?
    ///A board or grade change needs to force navigation away from Practice Chart and Spin Wheel if they are open since they still show the previous grade.
    @Published var isSpinWheelActive: Bool = false
    @Published var isPracticeChartActive: Bool = false

    init() {
        let settings  = Settings.shared
        settings.load()
        Settings.shared.load()
        self.selectedTab = 0
//        DispatchQueue.main.async {
//            if Settings.shared.aValidUserIsDefined() {
//                self.publishedUser = settings.getCurrentUser()
//                self.selectedTab = TabContainerView.TAB_ACTIVITES
//            }
//            else {
//                self.selectedTab = TabContainerView.TAB_USERS
//            }
//        }
    }
    
    func updatePublishedUser() {
        DispatchQueue.main.async {
            let user = Settings.shared.getCurrentUser()
            self.publishedUser = user
        }
    }
    
    func setTab(tab:Int) {
        DispatchQueue.main.async {
            self.objectWillChange.send()
            self.selectedTab = tab
        }
    }
}

struct TabContainerView: View {
    @ObservedObject private var viewManager = ViewManager.shared
    
    init() {
        // Customize tab bar appearance (System-wide)
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground() // Ensures the tab bar is solid
        appearance.backgroundColor = UIColor.white //

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
        
    var body: some View {
        TabView(selection: $viewManager.selectedTab) {
//            if true && Settings.shared.isDeveloperModeOn() {
//                if Settings.shared.aValidUserIsDefined() {
//                    //NavigationStack {
//                        //HomeView()
//                        ScalesView(user: Settings.shared.getCurrentUser(), practiceChart: nil, practiceChartCell: nil, practiceModeHand: nil)
//                            .tabItem {
//                                Label("SCALE", systemImage: "house")
//                            }
//                            .tag(1)
//                            .environmentObject(viewManager)
//                    //}
//                }
//            }
                        
            //if Settings.shared.aValidUserIsDefined() {
            ActivitiesView()
                    .tabItem {
                        Label(NSLocalizedString("Activities", comment: "Menu"), systemImage: "house")
                    }
                    .tag(ViewManager.TAB_ACTIVITES)
                    .environmentObject(viewManager)
                    
            UserListView()
                .tabItem {
                    Label {
                        Text(NSLocalizedString("Users", comment: "Menu")).background(.white).bold()
                    } icon: {
                        Image(systemName: "graduationcap.fill").renderingMode(.original).foregroundColor(.green)
                    }
                }
                .tag(ViewManager.TAB_USERS)
                .environmentObject(viewManager)
            
            LicenseManagerView(contentSection: ContentSection(), email: "email.com")
                .tabItem {
                    Label(NSLocalizedString("Subscriptions", comment: "Menu"), systemImage: "checkmark.icloud")
                }
                .tag(40)
                .environmentObject(viewManager)

            SettingsView(user:Settings.shared.getCurrentUser())
                .tabItem {
                    Label(NSLocalizedString("Settings", comment: "Menu"), systemImage: "gear")
                }
                .tag(30)
                .environmentObject(viewManager)
                
            //}
                        
//            FeatureReportView()
//                .tabItem {
//                    Label(NSLocalizedString("MessageUs", comment: "Menu"), systemImage: "arrow.up.message")
//                }
//                .tag(50)
//                .environmentObject(viewManager)
            
            WelcomeView()
                .tag(ViewManager.TAB_WELCOME)

            if Settings.shared.isDeveloperModeOn() {
                MIDIView()
                    .tabItem {
                        Label("MIDI", systemImage: "house")
                    }
                    .tag(89)
                    .accessibilityIdentifier("app_log")
                    .environmentObject(viewManager)

                LogView()
                    .tabItem {
                        Label("Log", systemImage: "book.pages")
                    }
                    .tag(90)
                    .accessibilityIdentifier("app_log")
                    .environmentObject(viewManager)
                
//                ScalesLibraryView()
//                    .tabItem {
//                        Label(NSLocalizedString("ScaleLibrary", comment: "Menu"), systemImage: "book")
//                    }
//                    .tag(60)
//                    .environmentObject(viewManager)
                
//                CalibrationView()
//                    .tabItem {
//                        Label("Calibration", systemImage: "lines.measurement.vertical")
//                    }
//                    .tag(70)
//                    .environmentObject(viewManager)
                
//                ScalesLibraryView()
//                    .tabItem {
//                        Label("ScaleLibrary", systemImage: "book.pages")
//                    }
//                    .tag(80)
//                    .environmentObject(viewManager)
//
                
//                DeveloperView()
//                    .tabItem {
//                        Label("Dev", systemImage: "book.pages")
//                    }
//                    .tag(100)
//                    .environmentObject(viewManager)
            }
        }
        .background(Color.white)
        .tabViewStyle(DefaultTabViewStyle())
        ///required to stop iPad putting tabView at top and overwriting some of the app's UI
        .environment(\.horizontalSizeClass, .compact)
    }
}

@main
struct ScalesTrainerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate ///Dont remove this ⬅️
    @ObservedObject private var viewManager = ViewManager.shared
    @StateObject var launchScreenState = LaunchScreenStateManager()
    let launchTimeSecs = 3.0

    init() {
#if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let err {
            AppLogger.shared.reportError(AVAudioSession.sharedInstance(), err.localizedDescription)
        }
#endif
    }
    
    func setupDev() {
        let scaleCustomisation = ScaleCustomisation(startMidiRH: 64, startMidiLH: 48, clefSwitch: false,
                                               customScaleName: "Chromatic, Contrary Motion, LH starting C, RH starting E",
                                               customScaleNameWheel: "Chrom Contrary, LH C, RH E")
        let scalesModel = ScalesModel.shared
        if true {
            let scale = scalesModel.setScaleByRootAndType(scaleRoot: ScaleRoot(name: "C"), scaleType: .major,
                                            scaleMotion: .similarMotion, minTempo: 50, octaves: 1, hands: [0],
                                            dynamicTypes: [.mf], articulationTypes: [.legato],
                                            //scaleCustomisation: scaleCustomisation,
                                            debugOn: true)
            MIDIManager.shared.testMidiNotes = TestMidiNotes(scale: scale, hands: [0], noteSetWait: 0.2, withErrors: false)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if Settings.shared.isDeveloperModeOn() {
                UserListView()
                    .onAppear() {
                        self.setupDev()
                    }
            }
            else {
                VStack {
                    if launchScreenState.state != .finished {
                        LaunchScreenView()
                    }
                    else {
                        TabContainerView()
                    }
                }
                .onAppear {
                    if Settings.shared.hasUsers() {
                        ViewManager.shared.selectedTab = ViewManager.TAB_ACTIVITES
                    }
                    else {
                        ViewManager.shared.selectedTab = ViewManager.TAB_WELCOME
                    }
                    ///Using CoreMIDI, check for available MIDI connections early, typically during app initialization, but not too early — CoreMIDI may not be fully ready at app launch.
                    MIDIManager.shared.setupMIDI()
                }
                
                .task {
                    DispatchQueue.main.asyncAfter(deadline: .now() + launchTimeSecs) {
                        self.launchScreenState.dismiss()
                    }
                }
            }
        }
    }
    
}

