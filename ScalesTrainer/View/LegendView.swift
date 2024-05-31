import SwiftUI

struct LegendView: View {
    @ObservedObject var logger = Logger.shared
    @ObservedObject var scalesModel = ScalesModel.shared
    @State private var scrollToEnd = false
    @State private var proxy: ScrollViewProxy? = nil
    @State private var legendIndex = 0
    let items = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"]
    
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
        var title:String = "Symbols"
//        if scalesModel.appMode == .practiceMode {
//            title = "Practice"
//        }
        if scalesModel.runningProcess == .followingScale {
            title = "Follow the Scale"
        }
        if [.recordingScale, .recordingScaleWithData].contains(scalesModel.runningProcess) {
            title = "Recording Scale"
        }
        return title
    }
    
    var body: some View {
        VStack {
            HStack {
                if let title = title() {
                    Text(" \(title) ").hilighted()
                }
                if scalesModel.showFingers {
                    Spacer()
                    Text("1").foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/).font(.title2).bold()
                    Text("Finger")
                    
                    Spacer()
                    Text("1").foregroundColor(.orange).font(.title2).bold()
                    Text(fingerChangeName())
                }
                
                if scalesModel.result != nil {
//                    Spacer()
//                    Circle()
//                        .fill(Color.green.opacity(0.4))
//                        .frame(width: width())
//                    Text("Correctly Played")
//                    Spacer()
//                    Circle()
//                        .fill(Color.red.opacity(0.4))
//                        .frame(width: width())
//                    Text("Played But Not in Scale")
//                    Spacer()
//                    Circle()
//                        .fill(Color.yellow.opacity(0.4))
//                        .frame(width: width())
//                    Text("In Scale But Not Played")
//                    
//                    Spacer()
//                    List(items, id: \.self) { item in
//                        Text(item)
//                    }
                    Picker("Select Value", selection: $legendIndex ) {
                        ForEach(scalesModel.directionTypes.indices, id: \.self) { index in
                            HStack {
                                //Text("\(scalesModel.directionTypes[index])")
                                Circle()
                                    .fill(Color.yellow.opacity(0.4))
                                    .frame(width: width())
                                    Text("In Scale But Not Played")
                            }
                        }
                    }
                    .pickerStyle(.menu)
                }

                ConfigView()//.padding()
            }
            if let instructions = scalesModel.processInstructions {
                Text("  👉 \(instructions)  ").hilighted()
            }
        }

    }
}
