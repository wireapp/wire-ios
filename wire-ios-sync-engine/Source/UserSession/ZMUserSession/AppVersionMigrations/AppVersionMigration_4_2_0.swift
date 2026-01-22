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

import Foundation
import WireDomain
import WireFoundation

// Issue: To simplify the logic, we rely solely on journal value to perform InitialSync or not
struct AppVersionMigration_4_2_0: AppVersionMigration {

    let appGroupIdentifier: String?
    let lastEventIDRepository: LastEventIDRepositoryInterface
    let journal: JournalProtocol
    let sessionManager: (any SessionManagerType)?
    let version: SemanticVersion = "4.2.0"

    func perform() async throws {

        if lastEventIDRepository.fetchLastEventID() == nil {
            journal[.isInitialSyncRequired] = true
        }

        deleteOldLogFiles()

        migrateAnalyticsTrackingUserDefaultsValue()

    }

    /// `FileLoggerDestination` protocol and `LogFileDestination.swift` have been deleted.
    /// This code cleans up potentially left-over files which could have been deleted by the removed code.
    private func deleteOldLogFiles() {
        let fileManager = FileManager.default

        // main app
        if let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let mainAppLogFileURL = cachesDirectory.appendingPathComponent("oslog_dump.log")
            try? fileManager.removeItem(at: mainAppLogFileURL)
        }

        // nse
        guard let appGroupIdentifier else { return }
        let containerDirectory = FileManager.sharedContainerDirectory(for: appGroupIdentifier)
        let nseLogFileURL = containerDirectory.appending(path: "oslog_NSE_dump.log", directoryHint: .notDirectory)
        try? fileManager.removeItem(at: nseLogFileURL)

        // se
        let seLogFileURL = containerDirectory.appending(path: "oslog_NSE_dump.log", directoryHint: .notDirectory)
        try? fileManager.removeItem(at: seLogFileURL)
    }

    /// Previously the decision for enabling analytics was stored only once per app and will be migrated to per account.
    private func migrateAnalyticsTrackingUserDefaultsValue() {
        let oldUserDefaultsKey = "disableAnalyticsSharing"
        guard
            let sessionManager,
            let sharedUserDefaults = UserDefaults.shared(),
            let disableAnalyticsSharing = sharedUserDefaults.value(forKey: oldUserDefaultsKey) as? Bool
        else { return }

        for account in sessionManager.accountManager.accounts {
            let userID = account.userIdentifier
            let privateUserDefaults = PrivateUserDefaults<AnalyticsTrackingPrivateUserDefaultsKey>(
                userID: userID,
                storage: UserDefaults.standard
            )
            privateUserDefaults.set(!disableAnalyticsSharing, forKey: .isAnalyticsTrackingEnabled)
        }

        sharedUserDefaults.removeObject(forKey: oldUserDefaultsKey)
    }

}
