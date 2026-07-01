import SwiftUI

struct DebugLogView: View {
    @ObservedObject private var debugLog = DebugLog.shared
    @State private var frozen = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Button(action: { frozen.toggle() }) {
                Text(frozen ? "▶" : "⏸")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 36)
                    .padding(.top, 6)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(debugLog.entries) { entry in
                            Text(String(format: "=== Exited SoundEventHandler  %d  MIDI:%d  vol:%.3f", entry.serial, entry.midi, entry.amplitude))
                                .font(.system(.body, design: .monospaced))
                                .id(entry.id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .onChange(of: debugLog.entries.count) {
                    if !frozen, let last = debugLog.entries.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color.black)
        .foregroundColor(.white)
    }
}
