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

// TODO: the new implementation currently just wraps the old one, rewrite!

struct NewCocoaLumberjackLogger: WireLogHandlerProtocol {

    var logger: CocoaLumberjackLogger

    func log(
        tag: WireLogTag,
        type: WireLogType,
        message: WireLogMessage,
        additionalAttributes: [WireLogAttribute]
    ) {
        switch type {
        case .debug:
            logger.debug(message.content, attributes: [.tag: tag.rawValue])
        case .info:
            logger.info(message.content, attributes: [.tag: tag.rawValue])
        case .notice:
            logger.notice(message.content, attributes: [.tag: tag.rawValue])
        case .warn:
            logger.warn(message.content, attributes: [.tag: tag.rawValue])
        case .error:
            logger.error(message.content, attributes: [.tag: tag.rawValue])
        case .critical:
            logger.critical(message.content, attributes: [.tag: tag.rawValue])
        }
    }

}

/// Logger to write logs to fileSystem via CocoaLumberjack

final class CocoaLumberjackLogger: LoggerProtocol, @unchecked Sendable {

    private let fileLogger: DDFileLogger
    private var tags = [LogAttributesKey: String]()
    private let tagsQueue = DispatchQueue(label: "CocoaLumberjackLogger.tagsQueue", attributes: .concurrent)

    /// - Parameter logsDirectory: If `nil` the default logs directory of `CocoaLumberjack` is used, otherwise the
    /// provided URL.
    init(logsDirectory: URL?) {
        let logFileManager = DDLogFileManagerDefault(logsDirectory: logsDirectory?.path())
        self.fileLogger = DDFileLogger(logFileManager: logFileManager)
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
        fileLogger.maximumFileSize = 100_000_000 // 100Mb
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)

        setupObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

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

    private func log(_ message: any LogConvertible, attributes: [LogAttributes], level: DDLogLevel) {

        var mergedAttributes: LogAttributes = [:]
        attributes.forEach {
            mergedAttributes.merge($0) { _, new in new }
        }

        let isSafe = mergedAttributes[.public] as? Bool == true
        guard isDebug || isSafe else {
            // skips logs in production builds with non redacted info
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

    func addTag(_ key: LogAttributesKey, value: String?) {
        tagsQueue.async(flags: .barrier) { [weak self] in
            if let value {
                self?.tags[key] = value
            } else {
                self?.tags.removeValue(forKey: key)
            }
        }
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
    }

    @objc
    private func appDidEnterBackground() {
        flushWithExpiringWindow(reason: "flushLogsOnDidEnterBackground")
    }

    @objc
    private func appWillTerminate() {
        flushWithExpiringWindow(reason: "flushLogsOnWillTerminate")
    }

    private func flushWithExpiringWindow(reason: String) {
        ProcessInfo.processInfo.performExpiringActivity(withReason: reason) { [weak self] expired in
            guard let self else { return }

            if expired {
                warn("Time's up for flush logs due to \(reason)", attributes: .safePublic)
                return
            }
            self.info("Flushing logs early due to \(reason)", attributes: .safePublic)
            fileLogger.flush()
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
