import SwiftUI

struct ViewSettingsView: View {
    @ObservedObject var logger = Logger.shared
    @ObservedObject var scalesModel = ScalesModel.shared
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                scalesModel.setShowKeyboard(!scalesModel.showKeyboard)
            }) {
                Text(scalesModel.showKeyboard ? "Hide Keyboard" : "Show Keyboard")
            }
            .padding()
            
            if scalesModel.showKeyboard {
                Spacer()
                Button(action: {
                    scalesModel.setShowFingers(!scalesModel.showFingers)
                }) {
                    Text(scalesModel.showFingers ? "Hide Fingers" : "Show Fingers")
                }
                .padding()
            }
            
            Spacer()
            Button(action: {
                scalesModel.setShowStaff(!scalesModel.showStaff)
            }) {
                Text(scalesModel.showStaff ? "Hide Staff" : "Show Staff")
            }
            .padding()
            
            Spacer()
        }
    }
}

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
                name = "Finger Over" // Note"
            }
            else {
                name = "Thumb Under" // Note"
            }
        }
        return name
    }
    
    func width() -> CGFloat {
        return CGFloat(UIScreen.main.bounds.size.width / 50)
    }
    
    func title() -> String? {
        var title:String = scalesModel.showKeyboard ? "Fingers" : ""
        if scalesModel.runningProcess == .leadingTheScale  {
            title = "Practice"
        }
        else {
            if scalesModel.resultPublished != nil {
                title = "Results"
            }
        }
        return title
    }
    
    var body: some View {
        VStack {
            HStack {
                if let title = title() {
                    Text("  \(title)  ").hilighted()
                }
                if scalesModel.resultPublished == nil {
                    if scalesModel.showKeyboard {
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
                }
                if scalesModel.runningProcess == .leadingTheScale {
                    Spacer()
                    Circle()
                        .stroke(Color.green.opacity(1.0), lineWidth: 3)
                        .frame(width: width())
                    Text("Correctly Played")
                    Spacer()
                    Circle()
                        .stroke(Color.red.opacity(1.0), lineWidth: 3)
                        .frame(width: width())
                    //Text("Played But Not in Scale")
                    Text("Not in Scale")
                    Spacer()
                }
                
                if let result = scalesModel.resultPublished  {
                    Spacer()
                    Circle()
                        .fill(Color.green.opacity(0.4))
                        .frame(width: width())
                    Text("Correctly Played")
                    if result.getTotalErrors() > 0 {
                        Spacer()
                        Circle()
                            .fill(Color.red.opacity(0.4))
                            .frame(width: width())
                        Text("Not in Scale")
                        Spacer()
                        Circle()
                            .fill(Color.yellow.opacity(0.4))
                            .frame(width: width())
                        //Text("In Scale But Not Played")
                        Text("Missing")
                    }
                    Spacer()
                }

                Spacer()
            }
            if let instructions = scalesModel.processInstructions {
                Text("  👉 \(instructions)  ").padding()
            }
        }

    }
}
