////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import OSLog

public protocol FileLoggerDestination {
    var log: URL? { get }
}

struct SystemLogger: LoggerProtocol {

    let persistQueue = DispatchQueue(label: "persistQueue")

    var lastReportTime: Date? {
        get {
            guard let interval = UserDefaults.standard.object(forKey: "com.wire.log.lastReportTime") as? TimeInterval else { return nil }
            return Date(timeIntervalSince1970: interval)
        }
        set {
            UserDefaults.standard.set(newValue?.timeIntervalSince1970, forKey: "com.wire.log.lastReportTime")
        }
    }

    var fileLogger = FileLogger()

    func persist(fileDestination: FileLoggerDestination) async {
        var entries: [String] = []
        do {
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let position: OSLogPosition
            if let lastReportTime {
                position = store.position(date: lastReportTime)
            } else {
                position = store.position(timeIntervalSinceLatestBoot: 0)
            }
            entries = try store
                .getEntries(at: position)
                .compactMap { $0 as? OSLogEntryLog }
                .filter { $0.subsystem == Bundle.main.bundleIdentifier! }
                .map { "[\($0.date.formatted(.iso8601))] [\($0.category)] \($0.composedMessage)" }
        } catch {
            warn(error.localizedDescription, attributes: .safePublic)
        }

        fileLogger.write(entries: entries, to: fileDestination.log)
    }

    func debug(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message, attributes: attributes, osLogType: .debug)
    }

    func info(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message, attributes: attributes, osLogType: .info)
    }

    func notice(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message, attributes: attributes, osLogType: .default)
    }

    func warn(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message, attributes: attributes, osLogType: .fault)
    }

    func error(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message, attributes: attributes, osLogType: .error)
    }

    func critical(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message, attributes: attributes, osLogType: .fault)
    }

    private func log(_ message: LogConvertible, attributes: LogAttributes?, osLogType: OSLogType) {
        var logger: OSLog = OSLog.default
        if let tag = attributes?["tag"] as? String {

            logger = loggers[tag] ?? OSLog(subsystem: Bundle.main.bundleIdentifier ?? "main", category: tag)
        }

        if attributes?["public"] as? Bool == true {
            if #available(iOSApplicationExtension 14.0, *) {
                os_log(osLogType, log: logger, "%{public}@", "\(message.logDescription)")
            } else {
                print("\(message.logDescription)")
            }

        } else {
            if #available(iOSApplicationExtension 14.0, *) {
                os_log(osLogType, log: logger, "\(message.logDescription)")
            } else {
                print("\(message.logDescription)")
            }
        }
    }
}

private var loggers: [String: OSLog] = [:]

public class FileLogger {

    var updatingHandle: FileHandle?

    func write(entries: [String], to url: URL?) {
        guard let currentLogPath = url?.path else { return }

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
            if let data = entries.joined(separator: "\n").data(using: .utf8) {
                try updatingHandle?.write(contentsOf: data)
            }
        } catch {
            updatingHandle = nil
        }
    }

    func closeFile() {
        updatingHandle?.closeFile()
        updatingHandle = nil
    }

    deinit {
        closeFile()
    }
}
