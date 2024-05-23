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
    
    func title() -> String? {
        var title:String?
        if scalesModel.appMode == .practiceMode {
            title = "Practice"
        }
        if scalesModel.appMode == .scaleFollow {
            title = "Follow the Scale"
        }
        return title
    }
    
    var body: some View {
        HStack {
            if scalesModel.appMode == .none || 
                scalesModel.appMode == .practiceMode ||
                scalesModel.appMode == .scaleFollow
            {
                if let title = title() {
                    Text("  \(title)  ")
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        )
                        .foregroundColor(.white)
                        .padding()
                }
                Spacer()
                Text("1").foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/).font(.title2).bold()
                Text("Finger Number")
                
                Spacer()
                Text("1").foregroundColor(.orange).font(.title2).bold()
                Text(fingerChangeName())
                
                Spacer()
                Circle()
                    .stroke(Color.green, lineWidth: 2)
                    .frame(width: width())
                Text("Note is Playing")
                Spacer()
                Circle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: width())
                Text("Not in Scale")

                Spacer()
            }
            
            if scalesModel.appMode == .assessWithScale {
                Text("  Record your scale  ")
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
        }
    }
}
