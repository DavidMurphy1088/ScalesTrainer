import SwiftUI

struct ProcessLogView: View {
    @ObservedObject private var processLog = ProcessLog.shared
    var onDismiss: () -> Void
    @State private var showTapLines = true

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Exercise Log")
                    .font(.headline)
                    .padding()
                Spacer()
                Button(showTapLines ? "HideTap" : "ShowTap") {
                    showTapLines.toggle()
                }
                .padding(.horizontal, 8)
                Button("Copy All") {
                    let text = (processLog.header.isEmpty ? "" : processLog.header + "\n") + filteredLines.joined(separator: "\n")
                    UIPasteboard.general.string = text
                }
                .padding(.horizontal, 8)
                Button("Close") { onDismiss() }
                    .padding()
            }
            .background(Color(.systemGray5))

            ScrollView([.vertical, .horizontal]) {
                VStack(alignment: .leading, spacing: 2) {
                    if !processLog.header.isEmpty {
                        Text(processLog.header)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.blue)
                            .padding(.bottom, 4)
                    }
                    ForEach(filteredLines, id: \.self) { line in
                        Text(line)
                            .font(.system(.caption, design: .monospaced))
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var filteredLines: [String] {
        if showTapLines {
            return processLog.lines
        }
        return processLog.lines.filter { !$0.contains("=tapUpdate") }
    }
}
