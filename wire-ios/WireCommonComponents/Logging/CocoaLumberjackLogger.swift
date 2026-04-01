//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import CocoaLumberjackSwift
import Foundation
import WireLogging
import WireSystem

/// Logger to write logs to the file-system via CocoaLumberjack.
///
/// Three modes are supported, selected at initialisation time via `LogWritingMode`:
/// - **normal** – continuous, asynchronous disk writes (existing behaviour).
/// - **off** – no disk I/O; all log calls are no-ops.
/// - **buffered** – messages are kept in memory and only written to disk on
///   memory warning, app backgrounding, termination, or an uncaught
///   NSException.
final class CocoaLumberjackLogger: LoggerProtocol {

    // MARK: - Private types

    /// CocoaLumberjack logger that accumulates messages in memory and writes
    /// them all to a `DDFileLogger` when `flushToFile()` is called.
    ///
    /// Thread-safety notes:
    /// - `log(message:)` is always dispatched onto `loggerQueue` by `DDLog`,
    ///   so `buffer` can be mutated there without a lock.
    /// - `flushToFile()` first calls `DDLog.flushLog()` which blocks until
    ///   DDLog's own queue is drained — guaranteeing every pending async
    ///   `DDLog.log(...)` call has been dispatched to `loggerQueue` before we
    ///   read the buffer.  The subsequent `loggerQueue.sync` then waits for
    ///   those dispatches to actually execute, so no messages are lost.
    /// - File writes are dispatched on `fileLogger.loggerQueue` to satisfy
    ///   DDFileLogger's own thread-safety requirements.
    private final class BufferedDDLogger: DDAbstractLogger {

        private var buffer: [DDLogMessage] = []
        let fileLogger: DDFileLogger

        init(fileLogger: DDFileLogger) {
            self.fileLogger = fileLogger
            super.init()
        }

        override func log(message logMessage: DDLogMessage) {
            // Always called on self.loggerQueue by DDLog — no lock needed.
            buffer.append(logMessage)
        }

        func flushToFile() {
            // 1. Drain DDLog's dispatch queue so every pending async log call
            //    has been handed off to self.loggerQueue.
            DDLog.flushLog()

            // 2. Read and clear the buffer on self.loggerQueue so we are sure
            //    all messages dispatched in step 1 are included.
            var messages: [DDLogMessage] = []
            loggerQueue.sync {
                messages = self.buffer
                self.buffer.removeAll()
            }

            guard !messages.isEmpty else { return }

            // 3. Write on fileLogger's own queue as required by DDAbstractLogger.
            fileLogger.loggerQueue.sync {
                for msg in messages {
                    self.fileLogger.log(message: msg)
                }
                self.fileLogger.flush()
            }
        }
    }

    // MARK: - Properties

    private let mode: LogWritingMode
    private let fileLogger: DDFileLogger?
    private let bufferedDDLogger: BufferedDDLogger?
    private var tags = [LogAttributesKey: String]()
    private let tagsQueue = DispatchQueue(label: "CocoaLumberjackLogger.tagsQueue", attributes: .concurrent)

    // Retains the previous uncaught-exception handler so we can chain to it.
    private static var previousUncaughtExceptionHandler: NSUncaughtExceptionHandler?
    // Weak reference used by the uncaught-exception handler to flush the buffer.
    private static weak var bufferedLoggerForCrashHandler: BufferedDDLogger?

    // MARK: - Initialisation

    /// - Parameters:
    ///   - logsDirectory: Directory for log files.  If `nil` CocoaLumberjack's
    ///     default is used.
    ///   - mode: Controls whether / how logs are written to disk.
    init(logsDirectory: URL?, mode: LogWritingMode = .normal) {
        self.mode = mode

        switch mode {
        case .off:
            fileLogger = nil
            bufferedDDLogger = nil

        case .normal:
            let logger = Self.makeFileLogger(logsDirectory: logsDirectory)
            DDLog.add(logger)
            fileLogger = logger
            bufferedDDLogger = nil

        case .buffered:
            let logger = Self.makeFileLogger(logsDirectory: logsDirectory)
            let buffered = BufferedDDLogger(fileLogger: logger)
            DDLog.add(buffered)
            fileLogger = logger
            bufferedDDLogger = buffered
        }

        setupObservers()

        if mode == .buffered {
            setupCrashHandler()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - LoggerProtocol

    func debug(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, level: .debug)
    }

    func info(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, level: .info)
    }

    func notice(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, level: .info)
    }

    func warn(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, level: .warning)
    }

    func error(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, level: .error)
    }

    func critical(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, level: .error)
    }

    func addTag(_ key: LogAttributesKey, value: String?) {
        tagsQueue.async(flags: .barrier) { [weak self] in
            if let value {
                self?.tags[key] = value
            } else {
                self?.tags.removeValue(forKey: key)
            }
        }
    }

    // MARK: - Private helpers

    private func log(_ message: any LogConvertible, attributes: [LogAttributes], level: DDLogLevel) {
        guard mode != .off else { return }

        var mergedAttributes: LogAttributes = [:]
        attributes.forEach {
            mergedAttributes.merge($0) { _, new in new }
        }

        let isSafe = mergedAttributes[.public] as? Bool == true
        guard isDebug || isSafe else {
            // skips logs in production builds with non-redacted info
            return
        }

        // Filter logs by level:
        // Only continue if we're running a DEBUG build or
        // the level is greater than or equal to error and lower than or equal to info.
        //
        // DDLogLevelOff     00000 0
        // DDLogLevelError   00001 1
        // DDLogLevelWarning 00011 3
        // DDLogLevelInfo    00111 7
        // DDLogLevelDebug   01111 15
        // DDLogLevelVerbose 11111 31
        // DDLogLevelAll  1..11111 UInt.max
        guard
            isDebug ||
            (level.rawValue >= DDLogLevel.error.rawValue && level.rawValue <= DDLogLevel.info.rawValue)
        else { return }

        var entry =
            "[\(formattedLevel(level))] \(message.logDescription)\(attributesDescription(from: mergedAttributes))"

        var currentTags: [LogAttributesKey: String] = [:]
        tagsQueue.sync {
            currentTags = tags
        }

        if !currentTags.isEmpty {
            let extraInfo = currentTags.map { key, value in "[\(key.rawValue):\(value)]" }.joined()
            entry += extraInfo
        }

        if let tag = mergedAttributes[.tag] as? String {
            entry = "[\(tag)] - \(entry)"
        }

        let formatedMessage = DDLogMessage(DDLogMessageFormat(stringLiteral: entry), level: level, flag: .from(level))
        DDLog.log(asynchronous: true, message: formatedMessage)
    }

    private static func makeFileLogger(logsDirectory: URL?) -> DDFileLogger {
        let logFileManager = DDLogFileManagerDefault(logsDirectory: logsDirectory?.path())
        let fileLogger = DDFileLogger(logFileManager: logFileManager)
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
        fileLogger.maximumFileSize = 100_000_000 // 100 MB
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        return fileLogger
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )

        if mode == .buffered {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(didReceiveMemoryWarning),
                name: UIApplication.didReceiveMemoryWarningNotification,
                object: nil
            )
        }
    }

    private func setupCrashHandler() {
        CocoaLumberjackLogger.bufferedLoggerForCrashHandler = bufferedDDLogger
        CocoaLumberjackLogger.previousUncaughtExceptionHandler = NSGetUncaughtExceptionHandler()
        NSSetUncaughtExceptionHandler { exception in
            CocoaLumberjackLogger.bufferedLoggerForCrashHandler?.flushToFile()
            CocoaLumberjackLogger.previousUncaughtExceptionHandler?(exception)
        }
    }

    // MARK: - App lifecycle

    @objc private func appDidEnterBackground() {
        switch mode {
        case .off: break
        case .normal: flushWithExpiringWindow(reason: "flushLogsOnDidEnterBackground")
        case .buffered: flushBufferedWithExpiringWindow(reason: "flushLogsOnDidEnterBackground")
        }
    }

    @objc private func appWillTerminate() {
        switch mode {
        case .off: break
        case .normal: flushWithExpiringWindow(reason: "flushLogsOnWillTerminate")
        case .buffered: flushBufferedWithExpiringWindow(reason: "flushLogsOnWillTerminate")
        }
    }

    @objc private func didReceiveMemoryWarning() {
        bufferedDDLogger?.flushToFile()
    }

    private func flushWithExpiringWindow(reason: String) {
        guard let fileLogger else { return }
        ProcessInfo.processInfo.performExpiringActivity(withReason: reason) { [weak self] expired in
            guard let self else { return }
            if expired {
                warn("Time's up for flush logs due to \(reason)", attributes: .safePublic)
                return
            }
            info("Flushing logs early due to \(reason)", attributes: .safePublic)
            fileLogger.flush()
        }
    }

    private func flushBufferedWithExpiringWindow(reason: String) {
        guard let bufferedDDLogger else { return }
        ProcessInfo.processInfo.performExpiringActivity(withReason: reason) { expired in
            if !expired {
                bufferedDDLogger.flushToFile()
            }
        }
    }

    private func formattedLevel(_ level: DDLogLevel) -> String {
        switch level {
        case .error:
            "ERROR"
        case .warning:
            "WARN"
        case .info:
            "INFO"
        case .debug:
            "DEBUG"
        default:
            "VERBOSE"
        }
    }

    private var isDebug: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
}
