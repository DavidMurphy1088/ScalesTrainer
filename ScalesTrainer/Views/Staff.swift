import SwiftUI

struct StaveView: View {
    // Example notes to display
    let notes = ["C", "D", "E", "F"]

    var body: some View {
        VStack {
            MusicSheetView(notes: notes)
        }
    }
}

// View that represents the musical staff
struct StaffView: View {
    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<5) { line in
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 1)
            }
        }
        .padding()
    }
}

class Note1 {
    static var index = 0
}

// View that represents a single musical note
struct NoteView: View {
    var note: String
    var index: Int
    
    var body: some View {
        Ellipse()
            .fill(Color.black)
            .frame(width: 20, height: 10)
            .offset(x: CGFloat(index) * 20.0, y: calculateYOffset(note: note))
            .animation(.easeInOut, value: note)
    }

    // Calculate the vertical offset based on the note
    func calculateYOffset(note: String) -> CGFloat {
        switch note {
        case "C":
            return 40
        case "D":
            return 30
        case "E":
            return 20
        case "F":
            return 10
        default:
            return 0
        }
    }
}

// Combines the staff and notes into one view
struct MusicSheetView: View {
    var notes: [String]
    func index() -> Int {
        Note1.index += 1
        return Note1.index
    }
    var body: some View {
        ZStack(alignment: .topLeading) {
            StaffView()
            VStack {
                ForEach(notes, id: \.self) { note in
                    NoteView(note: note, index: index())
                }
            }
        }
    }
}
