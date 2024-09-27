class RecordScaleProcess : MetronomeTimerNotificationProtocol {

    var beatCount = 0
    var leadInShown = false
    
    init() {
    }
    
    func metronomeStart() {
    }
    
    func metronomeTickNotification(timerTickerNumber: Int, leadingIn:Bool) -> Bool {
//        if beatCount < Settings.shared.getLeadInBeats() {
//            MetronomeModel.shared.setLeadingIn(way: true)
//            leadInShown = true
//            beatCount += 1
//            return false
//        }
//        if leadInShown {
//            MetronomeModel.shared.setLeadingIn(way: false)
//        }
        return false
    }
    
    func metronomeStop() {
    }
}
