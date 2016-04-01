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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import Foundation

@objc
public enum ZMVoiceChannelErrorCode : UInt {
    case OngoingGSMCall
    case SwitchToAudioNotAllowed
    case SwitchToVideoNotAllowed
    case NoFlowManager
    case NoMedia
    case VideoCallingNotSupported
    case VideoNotActive
}


private class CallingInitialisationObserverTokenImpl : CallingInitialisationObserverToken {
    var observerToken : AnyObject
    init(observerToken: AnyObject) {
        self.observerToken = observerToken
    }
}

public class ZMVoiceChannelError: NSError {
    
    init(errorCode: ZMVoiceChannelErrorCode) {
        super.init(domain: ZMVoiceChannelVideoCallErrorDomain, code: Int(errorCode.rawValue), userInfo: ZMVoiceChannelError.userInfoForErrorCode(errorCode))
    }
    
    static func userInfoForErrorCode(errorCode: ZMVoiceChannelErrorCode) -> [String: String] {
        switch errorCode {
        case .OngoingGSMCall:
            return [NSLocalizedDescriptionKey: "Cannot get flow manager"]
        case .SwitchToAudioNotAllowed:
            return [NSLocalizedDescriptionKey: "Swtich to audio is not allowed"]
        case .SwitchToVideoNotAllowed:
            return [NSLocalizedDescriptionKey: "Switch to video is not allowed"]
        case .NoFlowManager:
            return [NSLocalizedDescriptionKey: "Cannot get flow manager"]
        case .NoMedia:
            return [NSLocalizedDescriptionKey: "Too early: media is not established yet"]
        case .VideoCallingNotSupported:
            return [NSLocalizedDescriptionKey: "Video cannot be sent to this conversation"]
        case .VideoNotActive:
            return [NSLocalizedDescriptionKey: "Video is not currently active"]
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatal("init(coder:) has not been implemented")
    }
    
    public static func noFlowManagerError() -> ZMVoiceChannelError {
        return ZMVoiceChannelError(errorCode: ZMVoiceChannelErrorCode.NoFlowManager)
    }
    
    public static func noMediaError() -> ZMVoiceChannelError {
        return ZMVoiceChannelError(errorCode: ZMVoiceChannelErrorCode.NoMedia)
    }
    
    public static func videoCallNotSupportedError() -> ZMVoiceChannelError {
        return ZMVoiceChannelError(errorCode: ZMVoiceChannelErrorCode.VideoCallingNotSupported)
    }
    
    public static func switchToVideoNotAllowedError() -> ZMVoiceChannelError {
        return ZMVoiceChannelError(errorCode: ZMVoiceChannelErrorCode.SwitchToVideoNotAllowed)
    }
    
    public static func switchToAudioNotAllowedError() -> ZMVoiceChannelError {
        return ZMVoiceChannelError(errorCode: ZMVoiceChannelErrorCode.SwitchToAudioNotAllowed)
    }
    
    public static func ongoingGSMCallError() -> ZMVoiceChannelError {
        return ZMVoiceChannelError(errorCode: ZMVoiceChannelErrorCode.OngoingGSMCall)
    }
    
    public static func videoNotActiveError() -> ZMVoiceChannelError {
        return ZMVoiceChannelError(errorCode: ZMVoiceChannelErrorCode.VideoNotActive)
    }
}


public let CallingInitialisationNotificationName = "CallingInitialisationNotification"

@objc
public class CallingInitialisationNotification : ZMNotification {
    
    public var error : NSError!
    internal var errorCode : ZMVoiceChannelErrorCode!
    
    init() {
        super.init(name: CallingInitialisationNotificationName, object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public static func notifyCallingFailedWithErrorCode(errorCode: ZMVoiceChannelErrorCode) {
        let note = CallingInitialisationNotification()
        note.error = ZMVoiceChannelError.init(errorCode: errorCode)
        note.errorCode = errorCode
        NSNotificationCenter.defaultCenter().postNotification(note)
    }
    
    @objc public static func addObserverWithBlock(block: (CallingInitialisationNotification) -> Void) -> CallingInitialisationObserverToken {
        let internalToken = NSNotificationCenter.defaultCenter().addObserverForName(CallingInitialisationNotificationName, object: nil, queue: NSOperationQueue.currentQueue()) { (note: NSNotification) in
            block(note as! CallingInitialisationNotification)
        }
        
        return (CallingInitialisationObserverTokenImpl(observerToken: internalToken)) as CallingInitialisationObserverToken
    }
    
    public static func removeObserver(observer: CallingInitialisationObserverToken) {
        let internalObserver = observer as! CallingInitialisationObserverTokenImpl
        NSNotificationCenter.defaultCenter().removeObserver(internalObserver.observerToken, name: CallingInitialisationNotificationName, object: nil)
    }
    

}