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
import WireLegacyLogging

/// A service that runs interruptible migrations when the app
/// is updated from one version to another.
///
/// Once a migration is completed it will not be run again. However
/// if it could not complete then it will be retried, so each
/// migration should be written in a way that can handle repeated
/// executions.

public final class AppVersionMigrationService {

    var journal: any JournalProtocol
    let currentVersion: SemanticVersion
    let allMigrations: [any AppVersionMigration]

    public var isMigrationNeeded: Bool {
        !eligibleMigrations.isEmpty
    }

    public init(
        journal: any JournalProtocol,
        currentVersion: SemanticVersion,
        allMigrations: [any AppVersionMigration]
    ) {
        self.journal = journal
        self.currentVersion = currentVersion
        self.allMigrations = allMigrations

        assert(
            allMigrations.allSatisfy { $0.version <= currentVersion },
            "There should be no migration pinned to a future version"
        )

        assert(
            Set(allMigrations.map(\.version)).count == allMigrations.count,
            "There should only be one migration per version"
        )
    }

    public func performAppMigrations() async throws {
        // Find eligible migrations.
        var eligibleMigrations = eligibleMigrations.sorted {
            $0.version > $1.version
        }

        // Perform each migration.
        while let nextMigration = eligibleMigrations.popLast() {
            do {
                try await nextMigration.perform()
                journal.lastCompletedAppVersionMigration = nextMigration.version
                WireLogger.session.info(
                    "Completed migration to version \(nextMigration.version)",
                    attributes: .safePublic
                )
            } catch {
                WireLogger.session.error(
                    "Failed migration to version \(nextMigration.version): \(error)",
                    attributes: .safePublic
                )
                throw error
            }
        }
    }

    private var eligibleMigrations: [any AppVersionMigration] {
        let lastVersion = journal.lastCompletedAppVersionMigration ?? currentVersion
        return allMigrations.filter { $0.version > lastVersion }
    }

}

extension JournalProtocol {

    mutating func markInitialAppVersionForExistingAccount() {
        guard lastCompletedAppVersionMigration == nil else {
            return
        }

        // We mark this special null version because the account exists
        // and there is no marked version yet. This means the user has
        // upgraded from a version prior to this system, to a version
        // post this system. To ensure all known migrations are run, we
        // set the lowest possible version.
        lastCompletedAppVersionMigration = "0.0.0"
    }

    mutating func markInitialAppVersionForNewAccount(currentVersion: String) {
        guard lastCompletedAppVersionMigration == nil else {
            return
        }

        // We mark the current version because a new account should not
        // run any migration and there should be no migrations greater
        // than the current version.
        lastCompletedAppVersionMigration = SemanticVersion(stringLiteral: currentVersion)
    }

}

public extension JournalProtocol {

    var lastCompletedAppVersionMigration: SemanticVersion? {
        get {
            self[.lastCompletedAppVersionMigration].map(SemanticVersion.init)
        }
        set {
            self[.lastCompletedAppVersionMigration] = newValue?.string
        }
    }

}

extension JournalKey<String?> {

    static let lastCompletedAppVersionMigration = JournalKey(
        "lastCompletedAppVersionMigration",
        defaultValue: nil
    )

}
