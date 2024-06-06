import SwiftUI

struct LegendView: View {
    @ObservedObject var logger = Logger.shared
    @ObservedObject var scalesModel = ScalesModel.shared
    @State private var scrollToEnd = false
    @State private var proxy: ScrollViewProxy? = nil
    @State private var legendIndex = 0
    
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
        return CGFloat(UIScreen.main.bounds.size.width / 30)
    }
    
    func SettingsView() -> some View {
        HStack {
            Spacer()
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
        }
    }

    func title() -> String? {
        var title:String = "Fingers"
//        if scalesModel.userFeedback != nil {
//            title = "Feedback"
//        }
        if scalesModel.result != nil {
            title = "Notes"
        }
        return title
    }
    
    var body: some View {
        VStack {
            HStack {
                if let title = title() {
                    Text("  \(title)  ").hilighted()
                }
                if scalesModel.result == nil { //}&& scalesModel.userFeedback == nil {
                    if scalesModel.showFingers {
                        Spacer()
                        Text("1").foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/).font(.title2).bold()
                        Text("Finger")
                        
                        Spacer()
                        Text("1").foregroundColor(.orange).font(.title2).bold()
                        Text(fingerChangeName())
                        Spacer()
                    }
                }
//                else {
//                    if let feedback = scalesModel.userFeedback {
//                        Text(feedback)
//                    }
//                }
                
                if scalesModel.result != nil {
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
                Spacer()
                SettingsView()//.padding()
                Spacer()
            }
        }
        if let instructions = scalesModel.processInstructions {
            Text("  👉 \(instructions)  ").hilighted()
        }
    }
}
