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

private var logCache : CircularArray<String>? = nil
private var recordingToken : ZMSLog.LogHookToken? = nil

extension ZMSLog {
    
    /// Start recording
    public static func startRecording(size: Int = 10000) {
        logQueue.sync {
            if recordingToken == nil {
                logCache = CircularArray<String>(size: size)
                recordingToken = self.nonLockingAddHook(logHook: { (level, tag, message) -> (Void) in
                    let tagString = tag.flatMap { "[\($0)] "} ?? ""
                    logCache?.add("\(Date()): [\(level.rawValue)] \(tagString)\(message)")
                })
            }
        }
    }
    
    /// Returns a list of recorded log lines
    public static var recordedContent : [String] {
        var output : [String] = []
        logQueue.sync {
            output = logCache?.content ?? []
        }
        return output
    }
    
    /// Stop recording logs and discard cache
    public static func stopRecording() {
        var tokenToRemove : ZMSLog.LogHookToken?
        logQueue.sync {
            guard let token = recordingToken else { return }
            tokenToRemove = token
            logCache = nil
            recordingToken = nil
        }
        if let token = tokenToRemove {
            self.removeLogHook(token: token)
        }
    }
    
}
