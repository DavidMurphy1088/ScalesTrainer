import Foundation

///A note that was played that was not in the scale
public class UnMatchedType: Hashable {
    var notePlayedSequence:Int
    var midi:Int
    var amplitude:Double
    var time:Date
    var ascending:Bool
    
    init(notePlayedSequence:Int, midi:Int, amplitude:Double, time:Date, ascending:Bool) {
        self.notePlayedSequence = notePlayedSequence
        self.midi = midi
        self.amplitude = amplitude
        self.time = time
        self.ascending = ascending
    }
    
    public static func == (lhs: UnMatchedType, rhs: UnMatchedType) -> Bool {
        return lhs.notePlayedSequence == rhs.notePlayedSequence
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.notePlayedSequence)
    }
}

public class Event {
    let time:Date
    let midi:Int
    let inScale:Bool
    let amplitude:Double
    
    init(time:Date, inScale:Bool, midi:Int, amplitude:Double) {
        self.time = time
        self.inScale = inScale
        self.midi = midi
        self.amplitude = amplitude
    }
}

public class Result : ObservableObject {
    @Published var scale:Scale
    var notInScale:[UnMatchedType]
    let amplitudeFilter:Double
    let startAmplitude:Double

    public init(scale:Scale, notInScale:[UnMatchedType]) {
        self.scale = scale
        self.notInScale = notInScale
        self.amplitudeFilter = ScalesModel.shared.amplitudeFilter
        self.startAmplitude = ScalesModel.shared.requiredStartAmplitude ?? 0
    }
    
    ///Merge the scaled matched notes with the unmatched notes by time
    public func makeEventsSequence() -> [Event] {
        var events:[Event] = []
        for note in self.scale.scaleNoteStates {
            if let time = note.matchedTimeAscending {
                let event = Event(time: time, inScale: true, midi: note.midi, amplitude: note.matchedAmplitudeAscending ?? 0)
                events.append(event)
            }
        }
        for unmatch in self.notInScale {
            let event = Event(time: unmatch.time, inScale: false, midi: unmatch.midi, amplitude: unmatch.amplitude)
            events.append(event)
        }
        events = events.sorted { $0.time < $1.time }
        print("===== events")
        //normalize unamtched to range of scale
        for e in events {
            print ("event", e.time, "\tmidi:", e.midi, "ampl:", String(format: "%.4f", e.amplitude), "\tinScale:", e.inScale )
        }
        return events
    }
}
