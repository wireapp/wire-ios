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

// MARK: - Log level management

/// Map of the level set for each log tag
private var logTagToLevel : [String : ZMLogLevel_t] = [:]

extension ZMSLog {
    
    /// Sets the minimum logging level for the tag
    public static func set(level: ZMLogLevel_t, tag: String) {
        logQueue.sync {
            logTagToLevel[tag] = level
        }
    }
    
    /// Gets the minimum logging level for the tag
    public static func getLevel(tag: String) -> ZMLogLevel_t {
        var level = ZMLogLevel_t.warn
        logQueue.sync {
            if let currentLevel = logTagToLevel[tag] {
                level = currentLevel
            }
        }
        return level
    }
    
    /// Registers a tag for logging
    public static func register(tag: String) {
        logQueue.sync {
            if logTagToLevel[tag] == nil {
                logTagToLevel[tag] = ZMLogLevel_t.warn
            }
        }
    }
    
    /// Get all tags
    public static var allTags : [String] {
        var tags : [String] = []
        logQueue.sync {
            tags = Array(logTagToLevel.keys)
        }
        return tags
    }
}

// MARK: - Debugging
extension ZMSLog {
    
    static func debug_resetAllLevels() {
        logQueue.sync {
            logTagToLevel = [:]
        }
    }
    
}
