import SwiftUI

struct LegendView: View {
    @ObservedObject var logger = Logger.shared
    @ObservedObject var scalesModel = ScalesModel.shared
    @State private var scrollToEnd = false
    @State private var proxy: ScrollViewProxy? = nil
    
    func getColor(_ val:Double) -> Color {
        if val > logger.hiliteLogValue {
            return .red
        }
        return .black
    }
    
    func fingerChangeName() -> String {
        var name:String
        if scalesModel.selectedHandIndex == 0 {
            if scalesModel.selectedDirection == 0 {
                name = "Thumb Under"
            }
            else {
                name = "Finger Over"
            }
        }
        else {
            if scalesModel.selectedDirection == 0 {
                name = "Finger Over Note"
            }
            else {
                name = "Thumb Under Note"
            }
        }
        return name
    }
    
    func width() -> CGFloat {
        return CGFloat(UIScreen.main.bounds.size.width / 50)
    }
    
    func ConfigView() -> some View {
        HStack {
            Spacer()
//            Button(action: {
//                staffHidden.toggle()
//                scalesModel.scoreHidden = staffHidden
//                scalesModel.forceRepaint()
//            }) {
//                if staffHidden {
//                    HStack {
//                        Text("Show Staff")
////                        Image("eye_closed_trans")
////                            .resizable()
////                            .aspectRatio(contentMode: .fit)
////                            .frame(width: 30, height: 30)
////                            .foregroundColor(.green)
//                    }
//                }
//                else {
//                    HStack {
//                        Text("Hide Staff")
////                        Image("eye_open_trans")
////                            .resizable()
////                            .aspectRatio(contentMode: .fit)
////                            .frame(width: 30, height: 30)
////                            .foregroundColor(.red)
//                    }
//                }
//            }
            Button(action: {
                scalesModel.setShowStaff(!scalesModel.showStaff)
            }) {
                Text(scalesModel.showStaff ? "Hide Staff" : "Show Staff")
            }
            .padding()
            
            Spacer()
            Button(action: {
                scalesModel.setShowFingers(!scalesModel.showFingers)
            }) {
                Text(scalesModel.showStaff ? "Hide Fingers" : "Show Fingers")
            }
            .padding()

            Spacer()
//            Button(action: {
//                notesHidden.toggle()
//                scalesModel.staffHidden = notesHidden
//                scalesModel.forceRepaint()
//            }) {
//                if notesHidden {
//                    HStack {
//                        Text("Show Notes")
////                        Image("eye_closed_trans")
////                            .resizable()
////                            .aspectRatio(contentMode: .fit)
////                            .frame(width: 30, height: 30)
////                            .foregroundColor(.green)
//                    }
//                }
//                else {
//                    HStack {
//                        Text("Hide Notes")
////                        Image("eye_open_trans")
////                            .resizable()
////                            .aspectRatio(contentMode: .fit)
////                            .frame(width: 30, height: 30)
////                            .foregroundColor(.red)
//                    }
//                }
//            }
//            .padding()
        }
    }

    func title() -> String? {
        var title:String = "Symbols"
//        if scalesModel.appMode == .practiceMode {
//            title = "Practice"
//        }
        if scalesModel.followScale {
            title = "Follow the Scale"
        }
        return title
    }
    
    var body: some View {
        HStack {
            if true
            {
                if let title = title() {
                    Text(" \(title) ").hilighted()
//                        .background(
//                            RoundedRectangle(cornerRadius: 10)
//                                .fill(Color.blue)
//                        )
//                        .foregroundColor(.white)
//                        .padding()
                }
                Spacer()
                Text("1").foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/).font(.title2).bold()
                //Text("Finger Number")
                Text("Finger")

                Spacer()
                Text("1").foregroundColor(.orange).font(.title2).bold()
                Text(fingerChangeName())
                
//                Spacer()
//                Circle()
//                    .stroke(Color.green, lineWidth: 2)
//                    .frame(width: width())
//                Text("Note Playing")
//                Spacer()
//                Circle()
//                    .stroke(Color.red, lineWidth: 2)
//                    .frame(width: width())
//                Text("Not in Scale")

                Spacer()
            }
            
            if false { //scalesModel.appMode == .assessWithScale {
                Text("Record your scale")
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                    )
                    .foregroundColor(.white)
                    .padding()
                Spacer()
                Circle()
                    .fill(Color.green.opacity(0.4))
                    .frame(width: width())
                Text("Correctly Played")
                Spacer()
                Circle()
                    .fill(Color.red.opacity(0.4))
                    .frame(width: width())
                Text("Played But Not in Scale")
                Spacer()
                Circle()
                    .fill(Color.yellow.opacity(0.4))
                    .frame(width: width())
                Text("In Scale But Not Played")

                Spacer()
            }
            ConfigView().padding()
        }
    }
}
