import SwiftUI
import Combine
import UIKit

// Extension on UIDeviceOrientation to check for landscape mode
extension UIDeviceOrientation {
    var isAnyLandscape: Bool {
        return self == .landscapeLeft || self == .landscapeRight
    }
    
    var isPortrait: Bool {
        return self == .portrait || self == .portraitUpsideDown
    }
}

// ObservableObject to monitor device orientation changes
class DeviceOrientationObserver: ObservableObject {
    @Published var orientation: UIDeviceOrientation = UIDevice.current.orientation
    
    private var orientationDidChangeNotification: AnyCancellable?
    
    init() {
        orientationDidChangeNotification = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .compactMap { _ in
                return UIDevice.current.orientation
            }
            .assign(to: \.orientation, on: self)
        
        // Begin generating device orientation notifications
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }
    
    deinit {
        // Stop generating device orientation notifications
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        orientationDidChangeNotification?.cancel()
    }
}
