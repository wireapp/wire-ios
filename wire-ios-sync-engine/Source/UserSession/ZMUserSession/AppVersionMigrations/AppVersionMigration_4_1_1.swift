//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireDomain
import WireLogging

struct AppVersionMigration_4_1_1: AppVersionMigration {

    let logFilesProvider: LogFilesProviding
    let version: SemanticVersion = "4.1.1"

    func perform() async throws {
        // Deletes all raw log files collected from the logger sources.
        // This removes files from `WireLogger.logFiles` and `ZMSLog.pathsForExistingLogs`,
        try logFilesProvider.removeLogFiles()

        // Deletes all log-related archives and folders created in the temp directory.
        try logFilesProvider.removeLegacyLogArchives()
    }

}
