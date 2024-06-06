import SwiftUI

struct HelpView: View {
    let topic:String
    
    var body: some View {
        VStack {
            Text("").padding()
            Text("  \(topic)   ").font(.title2).hilighted()
            if let help = HelpMessages.shared.messages[topic] {
                Text(help)
                    .padding()
                    .padding()
            }
            Spacer()

        }
    }
}
