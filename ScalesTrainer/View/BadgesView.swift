import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

struct BadgesView: View {
    //@State var user:User
    ///NB 🟢 Reference types (e.g. User) state **don't refresh** the view with onAppear, use userName
    ///Therefore use name and grade changes to force the view to refresh (and therefore load the correct chart)
    //@State var userName:String = ""
    //@State var userGrade:Int?
    @State private var currentUser: User = Settings.shared.getCurrentUser()
    @State var imgSize = UIScreen.main.bounds.width * 0.2
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("badges")
            }
        }
    }
}
