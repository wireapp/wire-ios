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
import Testing
@testable import WireDomain

class AppVersionMigrationServiceTests {

    let currentVersion: SemanticVersion = "3.4.5"
    var migrationsPeformed = [SemanticVersion]()
    var migrationToInterrupt: SemanticVersion?

    var journal = Journal(
        userID: UUID(),
        storage: UserDefaults.temporary()
    )

    lazy var sut = AppVersionMigrationService(
        journal: journal,
        currentVersion: currentVersion,
        allMigrations: [
            createMigration(for: "1.0.1"),
            createMigration(for: "1.3.2"),
            createMigration(for: "2.0.0")
        ]
    )

    func createMigration(for version: SemanticVersion) -> MockMigration {
        MockMigration(version: version) {
            if self.migrationToInterrupt == $0 {
                throw "Interrupted migration: \($0)"
            }
            self.migrationsPeformed.append($0)
        }
    }

    @Test("No migrations run on first install")
    func noMigrationsRunOnFreshInstall() async throws {
        // Given
        #expect(journal[.lastCompletedAppVersionMigration] == nil)

        // When
        try await sut.performAppMigrations()

        // Then
        #expect(migrationsPeformed.isEmpty)
        #expect(journal[.lastCompletedAppVersionMigration] == nil)
    }

    @Test("No migrations run if last version is current")
    func noMigrationsRunIfLastVersionIsCurrent() async throws {
        // Given
        journal[.lastCompletedAppVersionMigration] = currentVersion.string

        // When
        try await sut.performAppMigrations()

        // Then
        #expect(migrationsPeformed.isEmpty)
        #expect(journal[.lastCompletedAppVersionMigration] == currentVersion.string)
    }

    @Test("No migrations run if none are eligible")
    func noMigrationsRunIfNoneAreEligbile() async throws {
        // Given
        journal[.lastCompletedAppVersionMigration] = "2.1.0"

        // When
        try await sut.performAppMigrations()

        // Then
        #expect(migrationsPeformed.isEmpty)
        #expect(journal[.lastCompletedAppVersionMigration] == "2.1.0")
    }

    @Test("One migration run if one is eligible")
    func oneMigrationIsRunIfOneIsEligble() async throws {
        // Given
        journal[.lastCompletedAppVersionMigration] = "1.9.0"

        // When
        try await sut.performAppMigrations()

        // Then
        #expect(migrationsPeformed == ["2.0.0"])
        #expect(journal[.lastCompletedAppVersionMigration] == "2.0.0")
    }

    @Test("Several migrations run if several are eligible")
    func severalMigrationsRunIfSeveralAreEligble() async throws {
        // Given
        journal[.lastCompletedAppVersionMigration] = "1.0.0"

        // When
        try await sut.performAppMigrations()

        // Then
        #expect(migrationsPeformed == ["1.0.1", "1.3.2", "2.0.0"])
        #expect(journal[.lastCompletedAppVersionMigration] == "2.0.0")
    }

    @Test("Interrupted migrations will be retried")
    func interruptedMigrationsWillBeRetried() async throws {
        // Given
        journal[.lastCompletedAppVersionMigration] = "1.0.0"
        migrationToInterrupt = "1.3.2"

        // When
        let error = await #expect(throws: String.self) {
            try await self.sut.performAppMigrations()
        }

        // Then
        #expect(error == "Interrupted migration: 1.3.2")
        #expect(migrationsPeformed == ["1.0.1"])
        #expect(journal[.lastCompletedAppVersionMigration] == "1.0.1")

        // When
        migrationToInterrupt = nil
        try await sut.performAppMigrations()

        // Then
        #expect(migrationsPeformed == ["1.0.1", "1.3.2", "2.0.0"])
        #expect(journal[.lastCompletedAppVersionMigration] == "2.0.0")
    }

}

struct MockMigration: AppVersionMigration {

    let version: SemanticVersion
    let block: (SemanticVersion) async throws -> Void

    func perform() async throws {
        try await block(version)
    }

}
