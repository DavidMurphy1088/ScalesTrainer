import Foundation
class HelpMessages {
    static let shared = HelpMessages()
    var messages: [String: String] = [:]
    
    init() {
        ///Activities
        var m = ""
        messages["Select Music Board"] = "Select the the music board that you are studying for. This determines which scales from which grades will appear in your practice chart."
        
        messages["Practice Journal"] = "Practice chart lists all the scales in your selected grade. The chart describes which scales should be practised each day. The chart also shows your progress on each scale."
        
        messages["Spin The Scale Wheel"] = "Pick a scale randomly from your practise chart to practise and record."
        
        //messages["Identify The Scale"] = "Listen to a random scale and identify the type of the scale."
        
        messages["Pick Any Scale"] = "Select any combination of scale root and type of scale to practise."
        
        messages["Your Coin Bank"] = "Shows all the gold coins in your scales bank. You can win coins as you record scales but if you make mistakes you loose coins."
        
        m = "Calibration is required so Scales Academy can accurately hear your piano and filter out background noise."
        m += "\n\n➤ For best recording results using your device's microphone your device should be placed near or directly against your piano."
        m += "\n\n➤ You will need to perform calibration again if you change the location of where the device is positioned when it listens to you play."
        m += "\n\n➤ Press Start Playing Scale and play the scale shown at a Mezzo-Forte (mf) dynamic and at a moderate tempo. Press Stop Playing when the scale is finished."
        m += "\n\n➤ Press Save Configuration to save the configuration."

        //m += " Then press Analyse Best Settings to save the calibration."
        //m += "\n\n➤ After Analyse Best Settings is finished some calibration value rows should show zero errors. If not, its best to redo the calibration."
        //m += "\n\n➤ Calibration will need to be reviewed if the app is not accurately hearing your scales. In particular, if notes you are play are not detected you may need to decrease the amplitude filter slightly. If notes appear that you did not play you may need to increase the amplitude filter slightly."

        messages["Calibration"] = m
        
        m = "Follow the scale helps you to learn the scale by following along as the notes of the scale are highlighted."
        m += "\n\n➤ Each note of the scale will be highlighted in turn. When the scale note is highlighted play the note on your piano. The keyboard shows the correct finger to use for every note of the scale."
        //m += "\n\n➤ When you follow the all notes both ascending and descending you will have completed the whole scale."
        m += "\n\n➤ Once you've learnt the pattern of the scale you can try following the scale without the fingers displayed to check if you remember the correct fingering."
        messages["Follow the Scale"] = m
        
        m = "Leading the scale lets you practise playing the scale by watching the notes you play appear on the keyboard and staff to check that they are correct."
        m += "\n\n➤ The displayed keyboard shows the right finger to use for each note."
        m += "\n\n➤ When you have learnt the scale try leading without the finger numbers displayed to see how well you remember the scale."
        messages["Lead the Scale"] = m
        
        m = "Play along on your piano at the same time as the scale is played. "
        m += "\n\n➤ The scale will be played ascending and descending. "
        m += "\n\n➤ Listen for any notes you play that are not in the scale. Make sure you use the correct fingering for each note."
        m += "\n\n➤ When you can play along without mistakes, try playing along with the finger numbers and keyboard turned off."
        messages["Play Along"] = m
        
        m = "Backing provides a backing harmony that you can use when practising the scale."
        m += "\n\n➤ The backing adjusts to the key of your scale so you can hear how the scale sounds along with the harmony. "
        m += "\n\n➤ When you play the scale with backing on, correctly played notes will sound good with the backing harmony. Notice that notes not in the scale sound unpleasant against the backing harmony."
        messages["Backing"] = m
        
        m = "Record your playing to see how well you know the scale."
        //No keyboard or fingering is shown. This means recording is similiar to how you would play the scale in an exam."
        //m += "\n\n➤ You will hear the metronome lead in and when its finished start to play the scale."
        m += "\n\n➤ Make sure to play your scale accurately and evenly. When your recording is complete, you can listen to your recording."
        messages["Record the Scale"] = m

        m = "Listen to the last scale recording you made."
        messages["Hear Recording"] = m
        
        m = "Listen to your recording synchronised to the scale."
        messages["Sync The Scale"] = m
        
        m = "Use the Practice Chart to regularly cover all of your Grade 1 Technical Work."
        m += "\n\nThe days of the week will automatically update themselves."
        m += "\n\nDon’t forget to choose your minor scale preference."
        m += "\n\nYou can fill in a star if your teacher has covered the scale or broken chord with you."
        m += "\n\nWhen you know all of your technical work, you can shuffle the practice chart to give you a new order. At this stage you can also spin the wheel to choose your technical work at random."
        
        messages["Practice Chart"] = m
    }
}
