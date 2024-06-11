import Foundation
class HelpMessages {
    static let shared = HelpMessages()
    var messages: [String: String] = [:]
    init() {
        var m = "Follow the scale helps you to learn the scale by following along as the notes of the scale are hilighted. \n\nEach note of the scale will be highlighted in turn. When the scale note is highlighted play the note on your piano. Then the next note will be hilighted. The keyboard shows the correct finger to use for every note of the scale. \n\nWhen you follow the all notes both ascending and descending you will have completed the whole scale."
        messages["Follow The Scale"] = m
        
        m = "Practice lets you practice playing the scale by listening to the notes you play. \n\nRead the displayed keyboard to make sure you are using the right finger for each note. \n\nWhen you have learnt the scale trying practicing without the finger numbers displayed to see how well you know the scale. \n\nTry practicing with backing on so you can hear how your scale sounds good over the backing harmony when you play the scale correctly."
        messages["Practice"] = m
        
        messages["Hear The Scale"] = "Hear the scale played ascending and descending. Watch the keyboard and staff to see which notes are played."
        
        messages["Backing"] = "Backing provides a backing harmony that you can use when practicing the scale. \n\nThe backing adjusts to the key of your scale so you can hear how the scale sounds alongside the harmony. Notice that notes not in the scale sound unpleasant against the backing harmony."
        
        m = "Record your playing to see how well you know the scale. \n\nYou will hear the metronome lead in and then you should start to play the scale. Make sure to play your scale accurately and evenly. When your recording is complete, you will see the results of your recording."
        messages["Record The Scale"] = m

    }
}
