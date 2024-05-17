import Foundation
import SwiftUI
import Combine

//struct MetronomeView: View {
//    @ObservedObject var viewModel = MetronomeModel.shared
//
//    var body: some View {
//        VStack {
//
//            Image("metronome-svgrepo-com") // Name of the image asset
//                        .resizable() // Make image resizable
//                        .aspectRatio(contentMode: .fit) // Maintain the aspect ratio
//                        .frame(width: 60, height: 60) // Optional: Set the frame
//            //Spacer()
//
//            // Controls for tempo
//            HStack {
////                Button("Decrease") {
////                    viewModel.tempo = max(40, viewModel.tempo - 5)
////                }
////                Button(viewModel.isRunning ? "Stop" : "Start \(viewModel.tempo)") {
////                    viewModel.isRunning ? viewModel.stop() : viewModel.start(tickCall: {})
////                }
//                Text("\(viewModel.tempo)")
//                .foregroundColor(.white)
//                .padding()
//                .background(Color.blue)
//                .cornerRadius(8)
//
//                Button("Increase") {
//                    //viewModel.tempo = min(208, viewModel.tempo + 5)
//                    viewModel.tempo = min(320, viewModel.tempo + 5)
//                }
//            }
//
//            //Spacer()
//        }
//        .padding()
//    }
//}

