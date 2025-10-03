import SwiftUI
import Foundation
import Combine
import Accelerate
import AVFoundation
import AudioKit

struct ChooseYourExerciseView: View {
    @Environment(\.dismiss) var dismiss
    @State private var user:User?

    var body: some View {
        VStack(spacing: 0)  {
            Text"Choose "
        }
        .commonToolbar(
            title: "Choose Your Exercise",
            onBack: { dismiss() }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear() {
            let user = Settings.shared.getCurrentUser()
            self.user = user
            let practiceChart = user.getPracticeChart()
        }

//        .onChange(of: ViewManager.shared.isPracticeChartActive) {oldValue, newValue in
//            if newValue == false {
//                dismiss()
//            }
//        }
    }
}

