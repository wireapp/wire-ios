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

class AppVersionMigrationService {

    var journal: any JournalProtocol
    let currentVersion: SemanticVersion
    let allMigrations: [any AppVersionMigration]

    init(
        journal: any JournalProtocol,
        currentVersion: SemanticVersion,
        allMigrations: [any AppVersionMigration]
    ) {
        self.journal = journal
        self.currentVersion = currentVersion
        self.allMigrations = allMigrations
    }

    func performAppMigrations() async throws {
        // Get the last completed migration version.
        let lastVersion = journal.lastCompletedAppVersionMigration ?? currentVersion

        // Find eligible migrations.
        var eligibleMigrations = allMigrations
            .filter { $0.version > lastVersion }
            .sorted { $0.version > $1.version }

        // Perform each migration.
        while let nextMigration = eligibleMigrations.popLast() {
            try await nextMigration.perform()
            journal.lastCompletedAppVersionMigration = nextMigration.version
        }
    }

}

private extension JournalProtocol {

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
