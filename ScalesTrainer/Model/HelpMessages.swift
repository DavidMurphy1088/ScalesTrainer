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
        
        m = "➤ Wait for each note to be highlighted on the app’s keyboard then play it on your piano in response. The app’s keyboard will display the notes that you play too. The keyboard shows you the correct fingering to use."
        m += "\n\n➤ Once you’ve learnt the pattern you can try following along without the fingers displayed."
        messages["Follow"] = m
        
        m = "➤ Play your technical work on your piano from start to finish. The app’s keyboard will display the notes that you play, as you play them. Make any corrections that you need to."
        m += "\n\n➤ When you’re confident, try leading without the finger numbers displayed."
        messages["Lead"] = m
        
        m = "Play along on your piano at the same time as the scale is played. "
        m += "\n\n➤ The number of clicks for the lead in can be adjusted in Settings."
        m += "\n\n➤ The scale will be played ascending and descending. "
        m += "\n\n➤ Listen for any notes you play that are not in the scale. Make sure you use the correct fingering for each note."
        m += "\n\n➤ When you can play along without mistakes, try playing along with the finger numbers and keyboard turned off."
        messages["Play Along"] = m
        
        m = "➤ Record your playing and then listen back to it. Focus on playing accurately and evenly."
        //m += "\n\n➤ The number of clicks for the lead in can be adjusted in Settings."
        messages["Record"] = m
        
        m = "➤ The number of clicks for the lead in can be adjusted in Settings."
        m += "\n\n➤ Correctly played notes will sound good with the backing harmony while incorrect notes will sound unpleasant."
        m += "\n\n➤ In Settings you can change the instrument on the Backing Track."
        messages["Backing"] = m

        m = "Listen to the last recording you made."
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
