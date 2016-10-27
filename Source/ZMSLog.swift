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

/// A logging facility based on tags to switch on and off certain logs
///
/// - Note:
/// Usage. Add:
///
///     ```
///     private let zmLog = ZMLog(tag: "Networking")
///     ```
///
/// at the top of your .swift file and log with:
///     
///     zmLog.debug("Debug information")
///     zmLog.warn("A serious warning!")
///
@objc public class ZMSLog : NSObject {
   
    public typealias LogHook = (_ level: ZMLogLevel_t, _ tag: String?, _ message: String) -> (Void)
    
    /// Tag to use for this logging facility
    fileprivate let tag: String
    
    /// Log observers
    fileprivate static var logHooks : [UUID : LogHook] = [:]
    
    public init(tag: String) {
        self.tag = tag
        logQueue.sync {
            ZMSLog.register(tag: tag)
        }
    }
    
    /// Wait for all log operations to be completed
    public static func sync() {
        logQueue.sync {
            // no op
        }
    }
}

// MARK: - Emit logs
extension ZMSLog {
    
    public func error(_ message: String, file: String = #file, line: UInt = #line) {
        ZMSLog.logWithLevel(.error, message: message, tag: self.tag, file: file, line:line)
    }
    public func warn(_ message: String, file: String = #file, line: UInt = #line) {
        ZMSLog.logWithLevel(.warn, message: message, tag: self.tag, file: file, line:line)
    }
    public func info(_ message: String, file: String = #file, line: UInt = #line) {
        ZMSLog.logWithLevel(.info, message: message, tag: self.tag, file: file, line:line)
    }
    public func debug(_ message: String, file: String = #file, line: UInt = #line) {
        ZMSLog.logWithLevel(.debug, message: message, tag: self.tag, file: file, line:line)
    }
}

// MARK: - Conditional execution
// These let us run code only if the log level is set correspondingly. That can be usefull when creating the logging is expensive.
//
// zmLog.ifError {
//     // do expensive calculation of 'foo' here
//     zmLog.error("foo: \(foo)")
// }
extension ZMSLog {

    /// Executes the closure only if the log level is Warning or higher
    public func ifWarn(_ closure: () -> Void) -> Void {
        if ZMLogLevel_t.warn.rawValue <= ZMSLog.getLevel(tag: self.tag).rawValue {
            closure()
        }
    }
    
    /// Executes the closure only if the log level is Info or higher
    public func ifInfo(_ closure: () -> Void) -> Void {
        if ZMLogLevel_t.info.rawValue <= ZMSLog.getLevel(tag: self.tag).rawValue {
            closure()
        }
    }
    /// Executes the closure only if the log level is Debug or higher
    public func ifDebug(_ closure: () -> Void) -> Void {
        if ZMLogLevel_t.debug.rawValue <= ZMSLog.getLevel(tag: self.tag).rawValue {
            closure()
        }
    }
}

// MARK: - Hooks (log observing)
extension ZMSLog {
    
    // NOTE:         
    // I could use NotificationCenter for this, but I would have to deal with
    // passing and extracting (and downcasting and wrapping) the parameters from the user info dictionary
    // I prefer handling my own delegates
    
    /// Opaque token to unregister observers
    @objc public class LogHookToken : NSObject {

        /// Internal identifier
        fileprivate let token : UUID
        
        override init() {
            self.token = UUID()
            super.init()
        }
    }
    
    /// Notify all hooks of a new log
    fileprivate static func notifyHooks(level: ZMLogLevel_t, tag: String?, message: String) {
        self.logHooks.forEach { (_, hook) in
            hook(level, tag, message)
        }
    }
    
    /// Adds a log hook
    static public func addHook(logHook: @escaping LogHook) -> LogHookToken {
        var token : LogHookToken! = nil
        logQueue.sync {
            token = self.nonLockingAddHook(logHook: logHook)
        }
        return token
    }
    
    /// Adds a log hook without locking
    static public func nonLockingAddHook(logHook: @escaping LogHook) -> LogHookToken {
        let token = LogHookToken()
        self.logHooks[token.token] = logHook
        return token
    }
    
    
    /// Remove a log hook
    static public func removeLogHook(token: LogHookToken) {
        logQueue.sync {
            _ = self.logHooks.removeValue(forKey: token.token)
        }
    }
    
    /// Remove all log hooks
    static public func removeAllLogHooks() {
        logQueue.sync {
            self.logHooks = [:]
        }
    }
}

// MARK: - Internal stuff
extension ZMSLog {
    
    /// Log only if this log level is enabled for the tag, or no tag is set
    static func logWithLevel(_ level: ZMLogLevel_t, message: String, tag: String?, file: String = #file, line: UInt = #line) {
        logQueue.async {
            if let tag = tag {
                self.register(tag: tag)
            }
        
            if tag == nil || level.rawValue <= ZMSLog.getLevelNoLock(tag: tag!).rawValue {
                sharedASLClient.sendMessage("\(file):\(line) \(tag ?? "") \(message)", level: level)
                self.notifyHooks(level: level, tag: tag, message: message)
            }
        }
    }
}

// Shared ASL client used to log
private let sharedASLClient : ZMSASLClient = ZMSASLClient(identifier: Bundle.main.bundleIdentifier ?? "com.wire.zmessaging.test", facility: nil)

/// Synchronization queue
let logQueue = DispatchQueue(label: "ZMSLog")
