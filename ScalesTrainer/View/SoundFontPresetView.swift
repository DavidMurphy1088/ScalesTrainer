import SwiftUI
import AudioKit
import SoundpipeAudioKit
import AudioKitEX

struct SoundFontPresetView: View {
    @StateObject private var conductor = SamplerConductor()
    @State private var selectedPreset = 0
    @State private var selectedBank = 0
    @State private var showingSettings = false
    
    // Common General MIDI presets (0-127)
    let commonPresets = [
        (0, "Acoustic Grand Piano"),
        (1, "Bright Acoustic Piano"),
        (4, "Electric Piano 1"),
        (5, "Electric Piano 2"),
        (16, "Drawbar Organ"),
        (17, "Percussive Organ"),
        (24, "Acoustic Guitar (nylon)"),
        (25, "Acoustic Guitar (steel)"),
        (26, "Electric Guitar (jazz)"),
        (27, "Electric Guitar (clean)"),
        (32, "Acoustic Bass"),
        (33, "Electric Bass (finger)"),
        (40, "Violin"),
        (41, "Viola"),
        (48, "String Ensemble 1"),
        (56, "Trumpet"),
        (60, "French Horn"),
        (64, "Soprano Sax"),
        (65, "Alto Sax"),
        (73, "Flute"),
        (80, "Lead 1 (square)"),
        (81, "Lead 2 (sawtooth)"),
        (88, "Pad 1 (new age)"),
        (89, "Pad 2 (warm)"),
        (128, "Drum Kit") // Bank 128 in GM
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("AudioKit SoundFont Player \(AudioManager.backingSamplerFileName)")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Settings Button
            HStack {
                Spacer()
                Button("Settings") {
                    showingSettings = true
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            }
            
            // Current Selection Info
            VStack(spacing: 8) {
                Text("SoundFont: \(AudioManager.backingSamplerFileName).sf2")
                    .font(.headline)
                Text("Bank: \(selectedBank), Preset: \(selectedPreset)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let presetName = commonPresets.first(where: { $0.0 == selectedPreset })?.1 {
                    Text(presetName)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // Preset Selector (Quick Access)
            VStack(spacing: 15) {
                Text("Quick Presets")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(commonPresets.prefix(8)), id: \.0) { preset in
                            Button(action: {
                                selectedPreset = preset.0
                                selectedBank = preset.0 == 128 ? 128 : 0 // Drums use bank 128
                                conductor.loadSoundFontPreset(
                                    file: AudioManager.backingSamplerFileName,
                                    preset: selectedPreset,
                                    bank: selectedBank
                                )
                            }) {
                                VStack {
                                    Text("\(preset.0)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(preset.1)
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(8)
                                .background(selectedPreset == preset.0 ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedPreset == preset.0 ? .white : .primary)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Piano Keys with Note Names
            VStack(spacing: 10) {
                Text("Tap to Play Notes")
                    .font(.headline)
                
                // Octave selector
                HStack {
                    Text("Octave:")
                    ForEach(3...6, id: \.self) { octave in
                        Button("\(octave)") {
                            // This will update the piano keys to show different octave
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(6)
                    }
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach(60..<73, id: \.self) { note in // C4 to C5
                        Button(action: {
                            conductor.playNote(note: UInt8(note))
                        }) {
                            VStack(spacing: 2) {
                                Text(noteNames[note - 60])
                                    .font(.system(size: 12, weight: .medium))
                                Text("(\(note))")
                                    .font(.system(size: 8))
                                    .opacity(0.7)
                            }
                            .foregroundColor(.white)
                            .frame(height: 45)
                            .frame(maxWidth: .infinity)
                            .background(isBlackKey(note - 60) ? Color.black : Color.blue)
                            .cornerRadius(6)
                        }
                    }
                }
            }
            .padding()
            
            // Control Buttons
            HStack(spacing: 15) {
                Button("Test C4") {
                    conductor.playNote(note: 60) // Middle C
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("Test Scale") {
                    conductor.playScale()
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("All Notes Off") {
                    conductor.stopAllNotes()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingSettings) {
            SettingsView1(
                //soundFontName: $soundFontName,
                selectedPreset: $selectedPreset,
                selectedBank: $selectedBank,
                conductor: conductor
            )
        }
        .onAppear {
            conductor.start()
            conductor.loadSoundFontPreset(file: AudioManager.backingSamplerFileName, preset: selectedPreset, bank: selectedBank)
        }
        .onDisappear {
            conductor.stop()
        }
    }
    
    let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B", "C"]
    
    func isBlackKey(_ index: Int) -> Bool {
        let blackKeys = [1, 3, 6, 8, 10] // Sharp/flat notes in an octave
        return blackKeys.contains(index % 12)
    }
}

struct SettingsView1: View {
    @Binding var selectedPreset: Int
    @Binding var selectedBank: Int
    let conductor: SamplerConductor
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("SoundFont Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("SoundFont File Name")
                        .font(.headline)
//                    TextField("Enter filename without .sf2", text: $soundFontName)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Text("Example: GeneralMIDI, Piano, Drums")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Bank Number")
                        .font(.headline)
                    HStack {
                        Stepper(value: $selectedBank, in: 0...128) {
                            Text("Bank: \(selectedBank)")
                        }
                        Spacer()
                        Button("Reset") {
                            selectedBank = 0
                        }
                        .font(.caption)
                    }
                    Text("Usually 0 for melodic instruments, 128 for drums")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Preset Number")
                        .font(.headline)
                    HStack {
                        Stepper(value: $selectedPreset, in: 0...127) {
                            Text("Preset: \(selectedPreset)")
                        }
                        Spacer()
                        Button("Reset") {
                            selectedPreset = 0
                        }
                        .font(.caption)
                    }
                    Text("0-127 for different instruments")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button("Load & Test") {
                    conductor.loadSoundFontPreset(
                        file: AudioManager.backingSamplerFileName,
                        preset: selectedPreset,
                        bank: selectedBank
                    )
                    conductor.playNote(note: 60) // Test with Middle C
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

class SamplerConductor: ObservableObject {
    let engine = AudioEngine()
    let sampler = MIDISampler(name: "Sampler")
    
    init() {
        engine.output = sampler
    }
    
    func start() {
        do {
            try engine.start()
        } catch {
            print("AudioEngine couldn't start: \(error)")
        }
    }
    
    func stop() {
        engine.stop()
    }
    
    func loadSoundFontPreset(file: String, preset: Int, bank: Int = 0) {
        do {
            try sampler.loadSoundFont(file, preset: preset, bank: bank)
            print("Loaded SoundFont: \(file).sf2 - Bank: \(bank), Preset: \(preset)")
        } catch {
            print("Error loading SoundFont \(file): \(error)")
            // Try to load from bundle with full path as fallback
            if let sf2URL = Bundle.main.url(forResource: file, withExtension: "sf2") {
                do {
                    try sampler.loadSoundFont(sf2URL.path, preset: preset, bank: bank)
                    print("Loaded SoundFont from bundle path: \(file)")
                } catch {
                    print("Error loading SoundFont from path: \(error)")
                    print("Error loading SoundFont \(file): \(error)")
                }
            }
        }
        //listSoundFontInstruments(filename: file)
        //func examineSF2File() {
//        guard let filePath = Bundle.main.path(forResource: "NEW_FluidR3_GM", ofType: "sf2") else {
//                print("Could not find NEW_FluidR3_GM.sf2 in app bundle")
//                return
//            }
            
            //let instruments = getInstrumentNamesFromSF2(filePath: filePath)
            
//            print("Found \(instruments.count) instruments in NEW_FluidR3_GM.sf2:")
//            for instrument in instruments {
//                print("Program \(instrument.program), Bank \(instrument.bank): \(instrument.name)")
//            }

    }
    func playNote(note: UInt8, velocity: UInt8 = 127, channel: UInt8 = 0) {
        sampler.play(noteNumber: note, velocity: velocity, channel: channel)
        
        // Auto-stop note after 2 seconds (optional)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.sampler.stop(noteNumber: note, channel: channel)
        }
    }
    
    func stopNote(note: UInt8, channel: UInt8 = 0) {
        sampler.stop(noteNumber: note, channel: channel)
    }
    
    func stopAllNotes() {
        for note in 0...127 {
            sampler.stop(noteNumber: UInt8(note), channel: 0)
        }
    }
    
    func playScale() {
        let cMajorScale: [UInt8] = [60, 62, 64, 65, 67, 69, 71, 72] // C Major
        
        for (index, note) in cMajorScale.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3) {
                self.playNote(note: note)
            }
        }
    }
    
    // List all instruments in a SoundFont file
    func listSoundFontInstruments(filename: String) -> [(bank: Int, preset: Int, name: String)] {
        var instruments: [(bank: Int, preset: Int, name: String)] = []
        
        // Get the file URL
//        guard let sf2URL = Bundle.main.url(forResource: filename, withExtension: "sf2") else {
//            print("Could not find \(filename).sf2 in bundle")
//            return instruments
//        }
        
        // Create a temporary sampler to test loading
        let tempSampler = MIDISampler(name: "InstrumentScanner")
        
        // Test common General MIDI banks and presets
        let banksToTest = [0, 1, 8, 16, 32, 128] // Common banks
        let presetsToTest = Array(0...127) // All GM presets
        for bank in banksToTest {
            for preset in presetsToTest {
                do {
                    // Try to load this bank/preset combination
                    //try tempSampler.loadSoundFont(sf2URL.path, preset: preset, bank: bank)
                    try tempSampler.loadSoundFont(filename, preset: preset, bank: bank)
                    // If loading succeeded, this preset exists
                    let instrumentName = getInstrumentName(bank: bank, preset: preset)
                    instruments.append((bank: bank, preset: preset, name: instrumentName))
                    
                    print("Found: Bank \(bank), Preset \(preset) - \(instrumentName)")
                    
                } catch {
                    // This preset doesn't exist in this bank, continue
                    continue
                }
            }
        }
        
        // Sort by bank, then by preset
        instruments.sort { ($0.bank, $0.preset) < ($1.bank, $1.preset) }
        
        print("\nTotal instruments found: \(instruments.count)")
        return instruments
    }
    
    private func getInstrumentName(bank: Int, preset: Int) -> String {
        // General MIDI standard names
        let gmInstruments = [
            0: "Acoustic Grand Piano", 1: "Bright Acoustic Piano", 2: "Electric Grand Piano",
            3: "Honky-tonk Piano", 4: "Electric Piano 1", 5: "Electric Piano 2",
            6: "Harpsichord", 7: "Clavinet", 8: "Celesta", 9: "Glockenspiel",
            10: "Music Box", 11: "Vibraphone", 12: "Marimba", 13: "Xylophone",
            14: "Tubular Bells", 15: "Dulcimer", 16: "Drawbar Organ", 17: "Percussive Organ",
            18: "Rock Organ", 19: "Church Organ", 20: "Reed Organ", 21: "Accordion",
            22: "Harmonica", 23: "Tango Accordion", 24: "Acoustic Guitar (nylon)",
            25: "Acoustic Guitar (steel)", 26: "Electric Guitar (jazz)", 27: "Electric Guitar (clean)",
            28: "Electric Guitar (muted)", 29: "Overdriven Guitar", 30: "Distortion Guitar",
            31: "Guitar Harmonics", 32: "Acoustic Bass", 33: "Electric Bass (finger)",
            34: "Electric Bass (pick)", 35: "Fretless Bass", 36: "Slap Bass 1",
            37: "Slap Bass 2", 38: "Synth Bass 1", 39: "Synth Bass 2",
            40: "Violin", 41: "Viola", 42: "Cello", 43: "Contrabass",
            44: "Tremolo Strings", 45: "Pizzicato Strings", 46: "Orchestral Harp",
            47: "Timpani", 48: "String Ensemble 1", 49: "String Ensemble 2",
            50: "Synth Strings 1", 51: "Synth Strings 2", 52: "Choir Aahs",
            53: "Voice Oohs", 54: "Synth Choir", 55: "Orchestra Hit",
            56: "Trumpet", 57: "Trombone", 58: "Tuba", 59: "Muted Trumpet",
            60: "French Horn", 61: "Brass Section", 62: "Synth Brass 1",
            63: "Synth Brass 2", 64: "Soprano Sax", 65: "Alto Sax",
            66: "Tenor Sax", 67: "Baritone Sax", 68: "Oboe", 69: "English Horn",
            70: "Bassoon", 71: "Clarinet", 72: "Piccolo", 73: "Flute",
            74: "Recorder", 75: "Pan Flute", 76: "Blown Bottle", 77: "Shakuhachi",
            78: "Whistle", 79: "Ocarina", 80: "Lead 1 (square)", 81: "Lead 2 (sawtooth)",
            82: "Lead 3 (calliope)", 83: "Lead 4 (chiff)", 84: "Lead 5 (charang)",
            85: "Lead 6 (voice)", 86: "Lead 7 (fifths)", 87: "Lead 8 (bass + lead)",
            88: "Pad 1 (new age)", 89: "Pad 2 (warm)", 90: "Pad 3 (polysynth)",
            91: "Pad 4 (choir)", 92: "Pad 5 (bowed)", 93: "Pad 6 (metallic)",
            94: "Pad 7 (halo)", 95: "Pad 8 (sweep)", 96: "FX 1 (rain)",
            97: "FX 2 (soundtrack)", 98: "FX 3 (crystal)", 99: "FX 4 (atmosphere)",
            100: "FX 5 (brightness)", 101: "FX 6 (goblins)", 102: "FX 7 (echoes)",
            103: "FX 8 (sci-fi)", 104: "Sitar", 105: "Banjo", 106: "Shamisen",
            107: "Koto", 108: "Kalimba", 109: "Bagpipe", 110: "Fiddle",
            111: "Shanai", 112: "Tinkle Bell", 113: "Agogo", 114: "Steel Drums",
            115: "Woodblock", 116: "Taiko Drum", 117: "Melodic Tom", 118: "Synth Drum",
            119: "Reverse Cymbal", 120: "Guitar Fret Noise", 121: "Breath Noise",
            122: "Seashore", 123: "Bird Tweet", 124: "Telephone Ring", 125: "Helicopter",
            126: "Applause", 127: "Gunshot"
        ]
        
        // Special handling for percussion bank (128)
        if bank == 128 {
            return "Drum Kit (Preset \(preset))"
        }
        
        // Return GM name if available, otherwise generic name
        if let gmName = gmInstruments[preset] {
            return bank == 0 ? gmName : "\(gmName) (Bank \(bank))"
        } else {
            return "Instrument Bank \(bank) Preset \(preset)"
        }
    }
    

}

