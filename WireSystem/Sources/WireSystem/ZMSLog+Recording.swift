//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

private var recordingToken: LogHookToken?

public extension ZMSLog {

    /// Start recording
    @objc static func startRecording(isInternal: Bool = true) {
        logQueue.sync {
            if recordingToken == nil {
                recordingToken = self.nonLockingAddEntryHook(logHook: { level, tag, entry, isSafe in
                    guard isInternal || isSafe else { return }
                    let tagString = tag.flatMap { "[\($0)] " } ?? ""
                    let date = dateFormatter.string(from: entry.timestamp)
                    // Add newline if it does not have it yet
                    let text = entry.text.hasSuffix("\n") ? entry.text : entry.text + "\n"
                    ZMSLog.appendToCurrentLog("\(date): [\(level.rawValue)] \(tagString)\(text)")
                })
            }
        }
    }

    /// Stop recording logs and discard cache
    @objc static func stopRecording() {
        var tokenToRemove: LogHookToken?
        logQueue.sync {
            guard let token = recordingToken else { return }
            tokenToRemove = token
            ZMSLog.clearLogs()
            recordingToken = nil
        }
        if let token = tokenToRemove {
            removeLogHook(token: token)
        }
    }

    private static var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS Z"
        return df
    }()
}
