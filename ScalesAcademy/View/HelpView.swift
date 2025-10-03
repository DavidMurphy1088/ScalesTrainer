import SwiftUI

struct HelpView: View {
    let topic:String
    
    func getHelp(topic:String) -> String? {
        return HelpMessages.shared.messages[topic] ?? ""
    }
        
    var body: some View {
        VStack {
            Text("").padding()
            Text("  \(topic)   ").font(.title2)//.hilighted()
            if let help = getHelp(topic:topic) {
                Text(help)
                    .padding()
                    .padding()
            }
            Spacer()

        }
        .onAppear() {
        }
    }
}
