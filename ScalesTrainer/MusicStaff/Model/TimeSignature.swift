import Foundation

public class TimeSignature : Codable {
    public var top = 1
    public var bottom = 4
    public var isCommonTime = false
    public let visible:Bool
    
    public init(top:Int, bottom: Int, visible:Bool) {
        self.top = top
        self.bottom = bottom
        self.visible = visible
    }
}
