import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

struct CustomBackButton: View {
    @Environment(\.presentationMode) var presentationMode
    let label:String

    var body: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back \(label)")
            }
        }
    }
}

class ActivityMode : Identifiable {
    let name:String
    let view:AnyView
    let imageName:String

    init(name:String, view:AnyView, imageName:String) {
        self.name = name
        self.view = view
        self.imageName = imageName
    }
}

struct UnderConstructionView: View {
    var body: some View {
        VStack {
            Text("Under Construction")
        }
    }
}

struct ActivitiesView: View {
    @State private var imgSize = UIScreen.main.bounds.width * 0.2

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    NavigationLink(destination: ChooseYourExerciseView()) {
                        Image("activity_pick_exercise")
                            .resizable()
                            .scaledToFit()
                            .frame(width: imgSize, height: imgSize)
                            .padding()
                    }

                    NavigationLink(destination: PracticeChartView()) {
                        Image("activity_practice_chart")
                            .resizable()
                            .scaledToFit()
                            .frame(width: imgSize, height: imgSize)
                            .padding()
                    }

                    NavigationLink(destination: SpinTheWheelView()) {
                        Image("activity_spin_wheel")
                            .resizable()
                            .scaledToFit()
                            .frame(width: imgSize, height: imgSize)
                            .padding()
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Activities")
            .navigationBarTitleDisplayMode(.inline)
            .commonToolbar(
                title: "Activities",
                helpMsg: "Choose how you'd like to practise. We recommend starting with the Practice Chart and leaving Spin the Wheel to last.",
                onBack: {}
            )
        }
    }
}
