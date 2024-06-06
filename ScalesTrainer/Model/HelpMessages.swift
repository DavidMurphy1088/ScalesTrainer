import Foundation
class HelpMessages {
    static let shared = HelpMessages()
    var messages: [String: String] = [:]
    init() {
        var m = "Follow the scale helps you to learn the scale by following along as the notes of the scale are hilighted. \n\nEach note of the scale will be highlighted in turn. When the scale note is highlighted play the note on your piano. Then the next note will be hilighted. The keyboard shows the correct finger to use for every note of the scale. \n\nWhen you follow the all notes both ascending and descending you will have played the whole scale."
        messages["Follow The Scale"] = m
        
        m = "Practice lets you practice playing the scale by listening to the notes you play. \n\nWatch the displayed keyboard to make sure all the notes you play are correct. When you have learnt the scale trying practicing without the finger numbers displayed to see how well you know the scale."
        messages["Practice"] = m
        
        messages["Hear The Scale"] = "Hear the scale played ascending and descending. Watch the keyboard to see which notes are played."
        
        messages["Backing"] = "Backing provides a backing harmony that you can use when practicing the scale. \n\nThe backing adjusts to the key of your scale so you can hear how the scale sounds alongside the harmony. Notice that notes not in the scale sound unpleasant against the backing harmony."
        
        m = "Record the scale to see how well you know the scale. \n\nYou will hear the metronome lead in and then you should start to play your scale. Make sure to play your scale accurately and evenly. When your recording is complete, you will see the results of your recording."
        messages["Record The Scale"] = m

    }
}
