import SwiftUI

enum LogLevel {
    case all
    case short
}

struct LogView: View {
    @ObservedObject var logger = Logger.shared
    @State private var scrollToEnd = false
    @State private var proxy: ScrollViewProxy? = nil
    
    func getColor(_ val:Double) -> Color {
        if val > logger.hiliteLogValue {
            return .red
        }
        return .black
    }
    
    var body: some View {
        VStack {
            if logger.minLogValue < logger.maxLogValue {
                Slider(
                    value: $logger.hiliteLogValue,
                    in: logger.minLogValue...logger.maxLogValue,
                    step: 1
                )
                .padding()
            }
            
            ScrollView {
                ScrollViewReader { proxy in
                    LazyVStack {
                        ForEach(logger.loggedMsgs.indices, id: \.self) { index in
                            // Wrap Text in a VStack (or other container)
                            HStack {
                                Text(logger.loggedMsgs[index].getLogEvent())
                                    .foregroundColor(getColor(logger.loggedMsgs[index].value))
                                Spacer()
                            }
                            .id(index) // <-- Important: Assigning unique IDs to each row
                            .frame(maxWidth: .infinity)
                            //.border(Color.green, width: 2)
                        }
                        .onChange(of: logger.loggedMsgs.count) { 
                            // Scroll to the last row whenever the number of logged messages changes
                            withAnimation {
                                proxy.scrollTo(logger.loggedMsgs.count - 1, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .border(Color.blue, width: 2)
        }
    }
}

