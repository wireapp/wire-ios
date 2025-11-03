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
import WireLegacyLogging

/// **Issue:** some users had conversations in their database that weren't
/// fully up do date with the backend.
/// **Fix:** mark conversations needing resync.

final class AppVersionMigration_4_1_1: AppVersionMigration {

    let version: SemanticVersion = "4.1.1"
    private var journal: any JournalProtocol
    private let logFilesProvider: LogFilesProviding

    init(
        journal: any JournalProtocol,
        logFilesProvider: LogFilesProviding
    ) {
        self.journal = journal
        self.logFilesProvider = logFilesProvider
    }

    func perform() async throws {
        // Syncing conversations may take time (due to number of
        // conversations and network speed) and this work is not
        // crucial, we simply mark the sync as needed and later
        // we'll perform it asynchronously.
        journal[.isConversationSyncRequired] = true

        // Deletes all raw log files collected from the logger sources.
        // This removes files from CocoaLumberjackLogger and `ZMSLog.pathsForExistingLogs`,
        try logFilesProvider.removeLogFiles(fileManager: .default)

        // Deletes all log-related archives and folders created in the temp directory.
        try logFilesProvider.removeLegacyLogArchives()
    }

}
