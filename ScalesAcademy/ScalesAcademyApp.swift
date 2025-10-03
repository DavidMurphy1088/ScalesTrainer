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
    @MainActor @Published private(set) var state: LaunchScreenStep =
        Settings.shared.isDeveloperModeOn() ? .finished : .firstStep
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
            .background(FigmaColors.appBackground)
        }
    }
}

struct DeveloperView: View {
    let scalesModel = ScalesModel.shared
    @State var showingTapData = false

    @State private var isLoggedIn = false
    @State var status = ""
    let logger = AppLogger.shared
    @State var ctr = 0
    let firebase = Firebase.shared
    
    var body: some View {
        VStack {
            Spacer()

//            Button("Firebase Signin") {
//                firebase.signIn(username: email, pwd: password)
//            }
//            Spacer()
            
            Button(action: {
                let x:[String : Any] = ["SomeTest":99]
                firebase.writeToRealtimeDatabase(board: "Trinity", grade: 1, key: "key0", data: x, callback: {msg in
                })
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
    //var orientationLock: UIInterfaceOrientationMask = UIInterfaceOrientationMask.landscape
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        
#if targetEnvironment(simulator)
        ///Simulator asks for password every time even though its signed in with Apple ID. By design for IAP purchasing... :(
        ///Code to run on the Simulator
        //AppLogger.shared.log(self, "Running on the Simulator, will not load IAP licenses")
#else
        //SKPaymentQueue.default().add(LicenceManager.shared) ///Do this as early as possible so manager is a queue observer
        //LicenceManager.shared.verifyStoredSubscriptionReceipt(ctx: "App starting") ///Get the current validity of any locally stored subscription receipt
        //LicenceManager.shared.requestProducts() ///Get products
        ///LicenceManager.shared.restoreTransactions() ///No need - the last subscription receipt received is stored locally. If not (e.g. nmew device) user does 'Restore Subscriptions'
#endif
        FirebaseApp.configure()
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
}

///------------------------------------------------------------

class ViewManager: ObservableObject {
    static let TAB_WELCOME = 100
    static let TAB_ACTIVITES = 10
    static let TAB_BADGES = 12
    static let TAB_USERS = 20

    static var shared = ViewManager()
    @Published var selectedTab: Int = 0
    @Published var currentUserPublished: User?
    @Published var gradePublished:Int = 0
    @Published var boardPublished:String = ""
    @Published var userNamePublished = ""
    @Published var userColorPublished = "" //hex color
    
    init() {
        self.selectedTab = 0
    }
    
    func updatePublishedUser(user:User) {
        DispatchQueue.main.async { [self] in
            self.currentUserPublished = user
            self.boardPublished = user.boardAndGrade.board.name
            self.gradePublished = user.boardAndGrade.grade
            self.userNamePublished = user.name
            self.userColorPublished = user.getColor()
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
    }
    
    private func setupTabBarAppearance() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.white // Tab bar background
        
        // Normal (unselected) state
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.black
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.black]
        tabBarAppearance.backgroundColor = UIColor(FigmaColors.shared.getColor1("BtmNavBar", "blue", 5))
    
        // Selected state
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.black
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.black]
        
        // Apply the appearance
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // For iOS 15+ compatibility
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
    
    var body: some View {
        TabView(selection: $viewManager.selectedTab) {
            if viewManager.selectedTab != ViewManager.TAB_WELCOME {
                ActivitiesView()
                    .tag(ViewManager.TAB_ACTIVITES)
                    .environmentObject(viewManager)
                    .tabItem {
                        Label {
                            Text("Activities")
                        } icon: {
                            Image("figma_tab_activities")
                                .renderingMode(.template)
                        }
                    }
                
//                BadgesView()
//                    .tag(ViewManager.TAB_BADGES)
//                    .environmentObject(viewManager)
//                    .tabItem {
//                        Label {
//                            Text("Badges")
//                        } icon: {
//                            Image("figma_tab_badges")
//                                .renderingMode(.template)
//                        }
//                    }

                UserListView()
                    .tag(ViewManager.TAB_USERS)
                    .environmentObject(viewManager)
                    .tabItem {
                        Label {
                            Text("Users")
                        } icon: {
                            Image("figma_tab_users")
                                .renderingMode(.template)
                        }
                    }
                
//                SettingsView()
//                    .tabItem {
//                        Label(
//                            NSLocalizedString("Settings", comment: "Menu"),
//                            systemImage: "gear"
//                        )
//                        //.foregroundColor(.black) // set color
//                        .labelStyle(.titleAndIcon)
//                    }
//                    .tag(30)
//                    .environmentObject(viewManager)
                        
//                LicenseManagerView()
//                    .tabItem {
//                        Label(NSLocalizedString("Subscriptions", comment: "Menu"), systemImage: "checkmark.icloud")
//                    }
//                    .tag(40)
//                    .environmentObject(viewManager)
//                    .environmentObject(licence)
//                    .task {
//                        // (Optional) refresh on first view
//                        await licence.refreshProducts()
//                        await licence.refreshEntitlements()
//                    }
                SubscriptionsView()
                    .tabItem {
                        Label(NSLocalizedString("Subscriptions", comment: "Menu"), systemImage: "checkmark.icloud")
                    }
                    .tag(40)
                    .environmentObject(viewManager)
            }
                        
//            FeatureReportView()
//                .tabItem {
//                    Label(NSLocalizedString("MessageUs", comment: "Menu"), systemImage: "arrow.up.message")
//                }
//                .tag(50)
//                .environmentObject(viewManager)
            

            if Settings.shared.isDeveloperModeOn() {
//                MIDIView()
//                    .tabItem {
//                        Label("MIDI", systemImage: "house")
//                    }
//                    .tag(89)
//                    .accessibilityIdentifier("app_log")
//                    .environmentObject(viewManager)

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
                SoundFontPresetView()
                    .tabItem {
                        Label("Sampler", systemImage: "book.pages")
                    }
                    .tag(91)
                    .environmentObject(viewManager)
                
//                DeveloperView()
//                    .tabItem {
//                        Label("Dev", systemImage: "music.note.tv")
//                    }
//                    .tag(100)
//                    .environmentObject(viewManager)
            }
            
//            WelcomeView()
//                .tag(ViewManager.TAB_WELCOME) ///Keep it last in list
        }
        //.background(Color.white)
        //.background(Color(FigmaColors.shared.colorShades[0].1))
        .tabViewStyle(DefaultTabViewStyle())
        ///required to stop iPad putting tabView at top and overwriting some of the app's UI
        .environment(\.horizontalSizeClass, .compact)
        .onAppear {
            setupTabBarAppearance()
        }
        .accentColor(.black) ///black tab icons
        
    }
}

class Paramters {
    var testMode:Bool = false
    static let shared = Paramters()
}

@main
struct ScalesTrainerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate ///Dont remove this ⬅️
    @StateObject var launchScreenState = LaunchScreenStateManager()
    @ObservedObject private var viewManager = ViewManager.shared
    
    let settings = Settings.shared
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
        Settings.shared.load()
        Paramters.shared.testMode = ProcessInfo.processInfo.arguments.contains("-testMode")
        Licencing.shared.configure(enableLicensing: !Paramters.shared.testMode, productIDs: ["100"])
        let _ = AudioManager.shared ///Cause it to load sf2 files
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
            VStack {
                if launchScreenState.state != .finished {
                    LaunchScreenView()
                }
                else {
                    if viewManager.currentUserPublished != nil { //Settings.shared.isCurrentUserDefined() {
                        TabContainerView()
                    }
                    else {
                        WelcomeView()
                    }
                }
            }
            .onAppear {
                if Settings.shared.hasUsers() {
                    if Settings.shared.isDeveloperModeOn() {
                        ViewManager.shared.selectedTab = ViewManager.TAB_ACTIVITES
                    }
                    else {
                        ViewManager.shared.selectedTab = ViewManager.TAB_ACTIVITES
                    }
                }
                else {
                    ViewManager.shared.selectedTab = ViewManager.TAB_WELCOME
                }
                ///Using CoreMIDI, check for available MIDI connections early, typically during app initialization, but not too early — CoreMIDI may not be fully ready at app launch.
                //MIDIManager.shared.setupMIDI()
            }
            .onAppear {
                NotificationCenter.default.addObserver(
                        forName: UIApplication.willTerminateNotification,
                        object: nil,
                        queue: nil
                    ) { _ in
                        try? AVAudioSession.sharedInstance().setActive(false)
                        print("✅ Microphone disconnected")
                    }
            }
            .task {
                DispatchQueue.main.asyncAfter(deadline: .now() + launchTimeSecs) {
                    self.launchScreenState.dismiss()
                }
            }
            
        }
    }
    
}
