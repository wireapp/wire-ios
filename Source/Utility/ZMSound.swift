// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


import Foundation
import AudioToolbox

public enum ZMSound: String, CustomStringConvertible {
    case Bell       = "bell"
    case Calipso    = "calipso"
    case Chime      = "chime"
    case Circles    = "circles"
    case Glass      = "glass"
    case Hello      = "hello"
    case Input      = "input"
    case Keys       = "keys"
    case Note       = "note"
    case Popcorn    = "popcorn"
    case Synth      = "synth"
    case Telegraph  = "telegraph"
    case TriTone    = "tri-tone"
    
    case Harp       = "harp"
    case Marimba    = "marimba"
    case OldPhone   = "old-phone"
    case Opening    = "opening"
    
    public static let allValues = [
        Bell,
        Calipso,
        Chime,
        Circles,
        Glass,
        Hello,
        Input,
        Keys,
        Note,
        Popcorn,
        Synth,
        Telegraph,
        TriTone,
        Harp,
        Marimba,
        OldPhone,
        Opening]
    
    public static let ringtones = [
        Harp,
        Marimba,
        OldPhone,
        Opening]
    
    public func isRingtone() -> Bool {
        return self.dynamicType.ringtones.contains(self)
    }
    
    private static var playingPreviewID: SystemSoundID?
    private static var playingPreviewURL: NSURL?
    
    private static func stopPlayingPreview() {
        if let _ = self.playingPreviewURL,
            let soundId = self.playingPreviewID {
            AudioServicesDisposeSystemSoundID(soundId)
            self.playingPreviewID = .None
            self.playingPreviewURL = .None
        }
    }
    
    public static func playPreviewForURL(mediaURL: NSURL) {
        self.stopPlayingPreview()
        
        self.playingPreviewURL = mediaURL
        var soundId: SystemSoundID = 0
        
        if AudioServicesCreateSystemSoundID(mediaURL, &soundId) == kAudioServicesNoError {
            self.playingPreviewID = soundId
        }
    
        AudioServicesPlaySystemSound(soundId)
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(4 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
            if self.playingPreviewID == soundId {
                self.stopPlayingPreview()
            }
        }
    }
    
    public func fileURL() -> NSURL {
        return NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource(self.rawValue, ofType: self.dynamicType.fileExtension)!)
    }
    
    private static let fileExtension = "m4a"

    public func filename() -> String {
        return (self.rawValue as NSString).stringByAppendingPathExtension(self.dynamicType.fileExtension)!
    }
    
    public var description: String {
        get {
            return self.rawValue.capitalizedString
        }
    }
    
    public func playPreview() {
        self.dynamicType.playPreviewForURL(self.fileURL())
    }
}
