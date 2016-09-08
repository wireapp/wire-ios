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

/// Logging for zmessaging in Swift
///
/// To use add
///     private let zmLog = ZMLog(tag: "Networking")
/// at the top of your .swift file and log with
///     zmLog.debug("Debug information")
///     zmLog.warn("A serious warning!")
///

public struct ZMSLog {
   
    fileprivate static var privateRegisteredTags : Set<String> = Set()
    
    /// List of registered tags
    public static var registeredTags : Set<String> {
        return privateRegisteredTags
    }
    
    fileprivate let tag: String
    
    public init(tag: String) {
        self.tag = tag
        
        ZMLogInitForTag(tag)
        
        let identifier = Bundle.main.bundleIdentifier ?? "com.wire.zmessaging.test"
        
        logClient = ZMSASLClient(identifier: identifier, facility: nil)
    }
    
    fileprivate let logClient : ZMSASLClient;
    
    public func error(_ message: @autoclosure () -> String, file: String = #file, line: UInt = #line) {
        logWithLevel(.error, message, file: file, line:line)
    }
    public func warn(_ message: @autoclosure () -> String, file: String = #file, line: UInt = #line) {
        logWithLevel(.warn, message, file: file, line:line)
    }
    public func info(_ message: @autoclosure () -> String, file: String = #file, line: UInt = #line) {
        logWithLevel(.info, message, file: file, line:line)
    }
    public func debug(_ message: @autoclosure () -> String, file: String = #file, line: UInt = #line) {
        logWithLevel(.debug, message, file: file, line:line)
    }
}

/// These let us run code only if the log level is set correspondingly. That can be usefull when creating the logging is expensive.
///
/// zmLog.ifError {
///     // do expensive calculation of 'foo' here
///     zmLog.error("foo: \(foo)")
/// }
extension ZMSLog {

    public func ifWarn(_ closure: () -> Void) -> Void {
        if (ZMLogLevel_t.warn.rawValue <= ZMLogGetLevelForTag((self.tag as NSString).utf8String).rawValue) {
            closure()
        }
    }
    public func ifInfo(_ closure: () -> Void) -> Void {
        if (ZMLogLevel_t.info.rawValue <= ZMLogGetLevelForTag((self.tag as NSString).utf8String).rawValue) {
            closure()
        }
    }
    public func ifDebug(_ closure: () -> Void) -> Void {
        if (ZMLogLevel_t.debug.rawValue <= ZMLogGetLevelForTag((self.tag as NSString).utf8String).rawValue) {
            closure()
        }
    }
}

/// Internal stuff
extension ZMSLog {
    
    fileprivate func logWithLevel(_ level: ZMLogLevel_t, _ message: @autoclosure () -> String, file: String = #file, line: UInt = #line) {
        if (level.rawValue <= ZMLogGetLevelForTag((self.tag as NSString).utf8String).rawValue) {
            let m = message()
            logToAppleSystemLogFacility(level, m, file: file, line: line)
        }
    }
    
    fileprivate func logToAppleSystemLogFacility(_ level: ZMLogLevel_t, _ message: String, file: String, line: UInt) {
        self.logClient.send(
            ZMSASLMessage(message: "\(file):\(line) \(message)", level: level.aslLevel)
        )
    }
    
}

extension ZMLogLevel_t {
    fileprivate var aslLevel: ZMASLLevel {
        switch (self) {
        case .error:
            return ZMASLLevel.error
        case .warn:
            return ZMASLLevel.warning
        case .info:
            return ZMASLLevel.notice
        case .debug:
            return ZMASLLevel.debug
        }
    }
}
