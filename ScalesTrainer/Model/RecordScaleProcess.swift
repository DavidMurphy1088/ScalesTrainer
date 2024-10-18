class RecordScaleProcess : MetronomeTimerNotificationProtocol {

    var beatCount = 0
    var leadInShown = false
    
    init() {
    }
    
    func metronomeStart() {
    }
    
    func metronomeTickNotification(timerTickerNumber: Int, leadingIn:Bool)  {
//        if beatCount < Settings.shared.getLeadInBeats() {
//            MetronomeModel.shared.setLeadingIn(way: true)
//            leadInShown = true
//            beatCount += 1
//            return false
//        }
//        if leadInShown {
//            MetronomeModel.shared.setLeadingIn(way: false)
//        }
    }
    
    func metronomeStop() {
    }
}
