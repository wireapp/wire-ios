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
import os.log

import ZipArchive

/// Represents an entry to be logged.
@objcMembers
public final class ZMSLogEntry: NSObject {
    public let text: String
    public let timestamp: Date

    internal init(text: String, timestamp: Date) {
        self.text = text
        self.timestamp = timestamp
    }
}

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
@objc
public final class ZMSLog: NSObject {

    public typealias LogHook = (_ level: ZMLogLevel_t, _ tag: String?, _ message: String) -> Void
    public typealias LogEntryHook = (
        _ level: ZMLogLevel_t,
        _ tag: String?,
        _ message: ZMSLogEntry,
        _ isSafe: Bool) -> Void

    /// Tag to use for this logging facility
    fileprivate let tag: String

    /// FileHandle instance used for updating the log
    fileprivate static var updatingHandle: FileHandle?

    /// Log observers
    fileprivate static var logHooks: [UUID: LogEntryHook] = [:]

    @objc public init(tag: String) {
        self.tag = tag
        logQueue.sync {
            ZMSLog.register(tag: tag)
        }
    }

    /// Wait for all log operations to be completed
    @objc
    public static func sync() {
        logQueue.sync {
            // no op
        }
    }
}

// MARK: - Emit logs
extension ZMSLog {

    public func safePublic(_ message: @autoclosure () -> SanitizedString,
                           level: ZMLogLevel_t = .info,
                           osLogOn: Bool = true,
                           file: String = #file,
                           line: UInt = #line) {
        let entry = ZMSLogEntry(text: message().value, timestamp: Date())
        ZMSLog.logEntry(entry, level: level, isSafe: true, tag: tag, osLogOn: osLogOn, file: file, line: line)
    }

    public func error(_ message: @autoclosure () -> String, file: String = #file, line: UInt = #line) {
        ZMSLog.logWithLevel(.error, message: message(), tag: self.tag, file: file, line: line)
    }
    public func warn(_ message: @autoclosure () -> String, file: String = #file, line: UInt = #line) {
        ZMSLog.logWithLevel(.warn, message: message(), tag: self.tag, file: file, line: line)
    }
    public func info(_ message: @autoclosure () -> String, file: String = #file, line: UInt = #line) {
        ZMSLog.logWithLevel(.info, message: message(), tag: self.tag, file: file, line: line)
    }
    public func debug(_ message: @autoclosure () -> String, file: String = #file, line: UInt = #line) {
        ZMSLog.logWithLevel(.debug, message: message(), tag: self.tag, file: file, line: line)
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
    public func ifWarn(_ closure: () -> Void) {
        if ZMLogLevel_t.warn.rawValue <= ZMSLog.getLevel(tag: self.tag).rawValue {
            closure()
        }
    }

    /// Executes the closure only if the log level is Info or higher
    public func ifInfo(_ closure: () -> Void) {
        if ZMLogLevel_t.info.rawValue <= ZMSLog.getLevel(tag: self.tag).rawValue {
            closure()
        }
    }
    /// Executes the closure only if the log level is Debug or higher
    public func ifDebug(_ closure: () -> Void) {
        if ZMLogLevel_t.debug.rawValue <= ZMSLog.getLevel(tag: self.tag).rawValue {
            closure()
        }
    }
}

// NOTE:
// I could use NotificationCenter for this, but I would have to deal with
// passing and extracting (and downcasting and wrapping) the parameters from the user info dictionary
// I prefer handling my own delegates

/// Opaque token to unregister observers
@objc(ZMSLogLogHookToken)
public final class LogHookToken: NSObject {

    /// Internal identifier
    fileprivate let token: UUID

    override init() {
        self.token = UUID()
        super.init()
    }
}

// MARK: - Hooks (log observing)
extension ZMSLog {

    /// Notify all hooks of a new log
    fileprivate static func notifyHooks(level: ZMLogLevel_t,
                                        tag: String?,
                                        entry: ZMSLogEntry,
                                        isSafe: Bool) {
        self.logHooks.forEach { (_, hook) in
            hook(level, tag, entry, isSafe)
        }
    }

    // MARK: - Rich Hooks

    /// Adds a log hook
    @objc static public func addEntryHook(logHook: @escaping LogEntryHook) -> LogHookToken {
        var token: LogHookToken! = nil
        logQueue.sync {
            token = self.nonLockingAddEntryHook(logHook: logHook)
        }
        return token
    }

    /// Adds a log hook without locking
    @objc static public func nonLockingAddEntryHook(logHook: @escaping LogEntryHook) -> LogHookToken {
        let token = LogHookToken()
        self.logHooks[token.token] = logHook
        return token
    }

    /// Remove a log hook
    @objc static public func removeLogHook(token: LogHookToken) {
        logQueue.sync {
            _ = self.logHooks.removeValue(forKey: token.token)
        }
    }

    /// Remove all log hooks
    @objc static public func removeAllLogHooks() {
        logQueue.sync {
            self.logHooks = [:]
        }
    }
}

// MARK: - Internal stuff

extension ZMSLog {

    @objc static public func logWithLevel(_ level: ZMLogLevel_t, message: @autoclosure () -> String, tag: String?, file: String = #file, line: UInt = #line) {
        let entry = ZMSLogEntry(text: message(), timestamp: Date())
        logEntry(entry, level: level, isSafe: false, tag: tag, file: file, line: line)
    }

    static private func logEntry(
        _ entry: ZMSLogEntry,
        level: ZMLogLevel_t,
        isSafe: Bool,
        tag: String?,
        osLogOn: Bool = true,
        file: String = #file,
        line: UInt = #line) {
        logQueue.async {
            guard let tag, level.rawValue <= ZMSLog.getLevelNoLock(tag: tag).rawValue else {
                return
            }

            var logLevel: OSLogType {
                switch level {
                case .public, .error, .warn:
                    return .error
                case .info:
                    return .info
                case .debug:
                    return .debug
                }
            }

            register(tag: tag)
            if osLogOn {
                os_log("%{public}@", log: self.logger(tag: tag), type: logLevel, entry.text)
            }
            notifyHooks(level: level, tag: tag, entry: entry, isSafe: isSafe)
        }
    }
}

// MARK: - Save on disk & file management

extension ZMSLog {
    private enum Constant {
        static let maxNumberOfLogFiles = 5
    }

    static var cachesDirectory: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    }

    @objc static public let currentLogURL: URL? = cachesDirectory?.appendingPathComponent("current.log")

    @objc static public var currentZipLog: Data? {
        FileManager.default.zipData(from: currentLogURL)
    }

    @objc static public let previousZipLogURLs: [URL] = {
        [0..<Constant.maxNumberOfLogFiles]
            .joined()
            .compactMap { index in
                cachesDirectory?.appendingPathComponent("previous_\(index).log.zip")
            }
    }()

    @objc public static func clearLogs() {
        guard let currentLogURL else { return }

        logQueue.async {
            closeHandle()
            let manager = FileManager.default

            // 2023-12-06: old deprecated previous log can be removed after some time.
            if let deprecatedPreviousLogURL = cachesDirectory?.appendingPathComponent("previous.log") {
                try? manager.removeItem(at: deprecatedPreviousLogURL)
            }

            previousZipLogURLs.forEach {
                try? manager.removeItem(at: $0)
            }

            try? manager.removeItem(at: currentLogURL)
        }
    }

    @objc public static func switchCurrentLogToPrevious() {
        guard let currentLogURL else { return }

        logQueue.async {
            closeHandle()

            if previousZipLogURLs.isEmpty {
                assertionFailure("expects 'previousLogPaths' not to be empty!")
                return
            }

            let lastIndex = previousZipLogURLs.count - 1

            // remove last item
            let manager = FileManager.default
            try? manager.removeItem(at: previousZipLogURLs[lastIndex])

            // move last-1 to 0 items
            for index in (0..<lastIndex).reversed() {
                try? manager.moveItem(at: previousZipLogURLs[index], to: previousZipLogURLs[index + 1])
            }

            // move current log to 0 item
            if manager.fileExists(atPath: currentLogURL.path) {
                // create a tmp different name from `current.log` to `previous.log`
                var tmpURL = currentLogURL.deletingLastPathComponent()
                tmpURL.appendPathComponent("previous.log")

                try? manager.moveItem(at: currentLogURL, to: tmpURL)

                // zip to position 0 logs
                SSZipArchive.createZipFile(atPath: previousZipLogURLs[0].path, withFilesAtPaths: [tmpURL.path])

                // remove tmp file
                try? manager.removeItem(at: tmpURL)
            }
        }
    }

    static public var pathsForExistingLogs: [URL] {
        var paths: [URL] = []
        previousZipLogURLs.forEach { url in
            if FileManager.default.fileExists(atPath: url.path) {
                paths.append(url)
            }
        }
        if let assertionFile = ZMLastAssertionFile(), FileManager.default.fileExists(atPath: assertionFile.path) {
            paths.append(assertionFile)
        }
        if let currentPath = currentLogURL, FileManager.default.fileExists(atPath: currentPath.path) {
            paths.append(currentPath)
        }
        return paths
    }

    static private func closeHandle() {
        updatingHandle?.closeFile()
        updatingHandle = nil
    }

    static func appendToCurrentLog(_ string: String) {
        guard let currentLogPath = currentLogURL?.path else { return }
        let manager = FileManager.default

        if !manager.fileExists(atPath: currentLogPath) {
            manager.createFile(atPath: currentLogPath, contents: nil, attributes: nil)
            // if there was no file, force to recreate the fileHandle
            updatingHandle = nil
        }

        if updatingHandle == nil {
            updatingHandle = FileHandle(forUpdatingAtPath: currentLogPath)
            updatingHandle?.seekToEndOfFile()
        }

        do {
            let data = Data(string.utf8)
            try updatingHandle?.write(contentsOf: data)
        } catch {
            updatingHandle = nil
        }
    }
}

/// Synchronization queue
let logQueue = DispatchQueue(label: "ZMSLog")

public extension FileManager {
    func zipData(from url: URL?) -> Data? {
        guard
            let url,
            self.fileExists(atPath: url.path)
        else {
            return nil
        }

        var tmpURL = url.deletingLastPathComponent()
        tmpURL.appendPathComponent("\(UUID().uuidString).zip")

        SSZipArchive.createZipFile(atPath: tmpURL.path, withFilesAtPaths: [url.path])
        defer {
            // clean up
            try? self.removeItem(at: tmpURL)
        }

        return try? Data(contentsOf: tmpURL, options: [.uncached])
    }
}
