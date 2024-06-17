import Foundation
class HelpMessages {
    static let shared = HelpMessages()
    var messages: [String: String] = [:]
    init() {
        var m = "Follow the scale helps you to learn the scale by following along as the notes of the scale are hilighted. \n\nEach note of the scale will be highlighted in turn. When the scale note is highlighted play the note on your piano. Then the next note will be hilighted. The keyboard shows the correct finger to use for every note of the scale. \n\nWhen you follow the all notes both ascending and descending you will have completed the whole scale.\n\nOnce you've learnt the pattern of the scale you can try following the scale without the fingers displayed to check if you remember the correct fingering."
        messages["Follow The Scale"] = m
        
        m = "Practice lets you practice playing the scale by watching the notes you play on the keyboard and staff to check that they are correct. \n\nCheck the displayed keyboard to make sure you are using the right finger for each note. \n\nWhen you have learnt the scale trying practicing without the finger numbers displayed to see how well you remember the scale."
        messages["Practice"] = m
        
        messages["Hear The Scale"] = "Hear the scale played ascending and descending. Watch the keyboard and staff to see which notes are played."
        
        messages["Backing"] = "Backing provides a backing harmony that you can use when practicing the scale. \n\nThe backing adjusts to the key of your scale so you can hear how the scale sounds alongside the harmony. \n\nWhen you play the scale with backing on, correctly played notes will sound good with the backing harmony. Notice that notes not in the scale sound unpleasant against the backing harmony."
        
        m = "Record your playing to see how well you know the scale. \n\nYou will hear the metronome lead in and then you should start to play the scale. Make sure to play your scale accurately and evenly. When your recording is complete, you will see the results of your recording."
        messages["Record The Scale"] = m

        m = "Listen to the last scale recording you made."
        messages["Hear Recording"] = m
        
        ///Activities
        ///
        messages["Selected Exam Scales"] = "Select the grade for you exam scales to determine which scales will appear in your practice journal."
        
        messages["Practice Journal"] = "Practice journal lists all the scales in your selected grade. The journal describes which scales should be practised each day. The journal also shows your progress on each scale."
        
        messages["Spin The Scale Wheel"] = "Pick a scale randomly from your journal to practise and record."
        
        messages["Identify The Scale"] = "Listen to a random scale and identify the type of the scale."
        
        messages["Pick Any Scale"] = "Select any combination of scale root and type of scale to practice."
    }
}
