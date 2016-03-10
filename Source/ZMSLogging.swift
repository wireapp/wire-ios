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


import Foundation

/// Logging for zmessaging in Swift
///
/// To use add
///     private let zmLog = ZMLog(tag: "Networking")
/// at the top of your .swift file and log with
///     zmLog.debug("Debug information")
///     zmLog.warn("A serious warning!")
///

public struct ZMSLog {
   
    private static var privateRegisteredTags : Set<String> = Set()
    
    /// List of registered tags
    public static var registeredTags : Set<String> {
        return privateRegisteredTags
    }
    
    private let tag: String
    
    public init(tag: String) {
        self.tag = tag
        
        ZMLogInitForTag(tag)
        
        let identifier = NSBundle.mainBundle().bundleIdentifier ?? "com.wire.zmessaging.test"
        
        logClient = ZMSASLClient(identifier: identifier, facility: nil)
    }
    
    private let logClient : ZMSASLClient;
    
    public func error(@autoclosure message: () -> String, file: String = __FILE__, line: UInt = __LINE__) {
        logWithLevel(.Error, message, file: file, line:line)
    }
    public func warn(@autoclosure message: () -> String, file: String = __FILE__, line: UInt = __LINE__) {
        logWithLevel(.Warn, message, file: file, line:line)
    }
    public func info(@autoclosure message: () -> String, file: String = __FILE__, line: UInt = __LINE__) {
        logWithLevel(.Info, message, file: file, line:line)
    }
    public func debug(@autoclosure message: () -> String, file: String = __FILE__, line: UInt = __LINE__) {
        logWithLevel(.Debug, message, file: file, line:line)
    }
}

/// These let us run code only if the log level is set correspondingly. That can be usefull when creating the logging is expensive.
///
/// zmLog.ifError {
///     // do expensive calculation of 'foo' here
///     zmLog.error("foo: \(foo)")
/// }
extension ZMSLog {

    public func ifWarn(closure: () -> Void) -> Void {
        if (ZMLogLevel_t.Warn.rawValue <= ZMLogGetLevelForTag((self.tag as NSString).UTF8String).rawValue) {
            closure()
        }
    }
    public func ifInfo(closure: () -> Void) -> Void {
        if (ZMLogLevel_t.Info.rawValue <= ZMLogGetLevelForTag((self.tag as NSString).UTF8String).rawValue) {
            closure()
        }
    }
    public func ifDebug(closure: () -> Void) -> Void {
        if (ZMLogLevel_t.Debug.rawValue <= ZMLogGetLevelForTag((self.tag as NSString).UTF8String).rawValue) {
            closure()
        }
    }
}

/// Internal stuff
extension ZMSLog {
    
    private func logWithLevel(level: ZMLogLevel_t, @autoclosure _ message: () -> String, file: String = __FILE__, line: UInt = __LINE__) {
        if (level.rawValue <= ZMLogGetLevelForTag((self.tag as NSString).UTF8String).rawValue) {
            let m = message()
            logToAppleSystemLogFacility(level, m, file: file, line: line)
        }
    }
    
    private func logToAppleSystemLogFacility(level: ZMLogLevel_t, _ message: String, file: String, line: UInt) {
        self.logClient.sendMessage(
            ZMSASLMessage(message: "\(file):\(line) \(message)", level: level.aslLevel)
        )
    }
    
}

extension ZMLogLevel_t {
    private var aslLevel: ZMASLLevel {
        switch (self) {
        case .Error:
            return ZMASLLevel.Error
        case .Warn:
            return ZMASLLevel.Warning
        case .Info:
            return ZMASLLevel.Notice
        case .Debug:
            return ZMASLLevel.Debug
        }
    }
}