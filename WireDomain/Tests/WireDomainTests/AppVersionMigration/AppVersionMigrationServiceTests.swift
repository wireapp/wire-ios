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
import Testing
@testable import WireDomain

final class AppVersionMigrationServiceTests {

    var migrationsPeformed = [SemanticVersion]()
    var migrationToInterrupt: SemanticVersion?

    var journal = Journal(
        userID: UUID(),
        storage: UserDefaults.temporary()
    )

    func makeSUT(
        currentVersion: SemanticVersion,
        migrations: [SemanticVersion]
    ) -> AppVersionMigrationService {
        AppVersionMigrationService(
            journal: journal,
            currentVersion: currentVersion,
            allMigrations: migrations.map(makeMigration)
        )
    }

    func makeMigration(for version: SemanticVersion) -> MockMigration {
        MockMigration(version: version) {
            if self.migrationToInterrupt == $0 {
                throw "Interrupted migration: \($0)"
            }
            self.migrationsPeformed.append($0)
        }
    }

    // MARK: - Special cases

    @Test("No migrations are run for new account", arguments: [
        TestData(
            description: "No migrations exist",
            allMigrations: [],
            currentVersion: "1.0.0",
            migrationsExpectedToBeRun: [],
            newMigrationMarker: "1.0.0"
        ),
        TestData(
            description: "One migration exists",
            allMigrations: ["1.0.0"],
            currentVersion: "1.0.0",
            migrationsExpectedToBeRun: [],
            newMigrationMarker: "1.0.0"
        ),
        TestData(
            description: "Several migrations exist",
            allMigrations: ["1.0.0", "1.2.0"],
            currentVersion: "1.2.0",
            migrationsExpectedToBeRun: [],
            newMigrationMarker: "1.2.0"
        )
    ])
    func noMigrationsRunForNewAccount(testData: TestData) async throws {
        // Given
        let sut = makeSUT(
            currentVersion: testData.currentVersion,
            migrations: testData.allMigrations
        )

        journal.markInitialAppVersionForNewAccount(
            currentVersion: testData.currentVersion.string
        )

        // When
        try await sut.performAppMigrations()

        // Then
        #expect(migrationsPeformed == testData.migrationsExpectedToBeRun)
        #expect(journal[.lastCompletedAppVersionMigration] == testData.newMigrationMarker.string)
    }

    @Test("Update from pre-service version", arguments: [
        TestData(
            description: "From pre to version service was introduced",
            allMigrations: ["1.0.1"],
            currentVersion: "1.0.1",
            migrationsExpectedToBeRun: ["1.0.1"],
            newMigrationMarker: "1.0.1"
        ),
        TestData(
            description: "A bigger jump (a few versions but one migration)",
            allMigrations: ["1.0.1"],
            currentVersion: "1.0.5",
            migrationsExpectedToBeRun: ["1.0.1"],
            newMigrationMarker: "1.0.1"
        ),
        TestData(
            description: "A even bigger jump (a few versions and several migrations)",
            allMigrations: ["1.0.1", "1.2.0", "1.5.2"],
            currentVersion: "1.5.2",
            migrationsExpectedToBeRun: ["1.0.1", "1.2.0", "1.5.2"],
            newMigrationMarker: "1.5.2"
        )
    ])
    func updateFromPreServiceVersion(testData: TestData) async throws {
        // Given
        let sut = makeSUT(
            currentVersion: testData.currentVersion,
            migrations: testData.allMigrations
        )

        journal.markInitialAppVersionForExistingAccount()

        // When
        try await sut.performAppMigrations()

        // Then
        #expect(migrationsPeformed == testData.migrationsExpectedToBeRun)
        #expect(journal[.lastCompletedAppVersionMigration] == testData.newMigrationMarker.string)
    }

    // MARK: - Normal upgrades

    @Test("Only eligible migrations are run", arguments: [
        TestData(
            description: "All migrations have already been run",
            allMigrations: ["1.0.0", "1.0.1"],
            prevMigrationMarker: "1.0.1",
            currentVersion: "1.0.1",
            migrationsExpectedToBeRun: [],
            newMigrationMarker: "1.0.1"
        ),
        TestData(
            description: "No new migrations",
            allMigrations: ["1.0.0", "1.0.1"],
            prevMigrationMarker: "1.0.1",
            currentVersion: "1.2.0",
            migrationsExpectedToBeRun: [],
            newMigrationMarker: "1.0.1"
        ),
        TestData(
            description: "One migration available upon update",
            allMigrations: ["1.0.0", "1.0.1"],
            prevMigrationMarker: "1.0.0",
            currentVersion: "1.0.1",
            migrationsExpectedToBeRun: ["1.0.1"],
            newMigrationMarker: "1.0.1"
        ),
        TestData(
            description: "Several migrations available upon update",
            allMigrations: ["1.0.0", "1.0.1", "1.2.0"],
            prevMigrationMarker: "1.0.0",
            currentVersion: "1.3.0",
            migrationsExpectedToBeRun: ["1.0.1", "1.2.0"],
            newMigrationMarker: "1.2.0"
        ),
        TestData(
            description: "Migrations are run in order",
            allMigrations: ["2.0.5", "1.1.0", "2.0.0", "1.0.1", "1.0.0"],
            prevMigrationMarker: "0.0.0",
            currentVersion: "3.0.0",
            migrationsExpectedToBeRun: ["1.0.0", "1.0.1", "1.1.0", "2.0.0", "2.0.5"],
            newMigrationMarker: "2.0.5"
        )
    ])
    func onlyEligibleMigrationsAreRun(testData: TestData) async throws {
        // Given
        let sut = makeSUT(
            currentVersion: testData.currentVersion,
            migrations: testData.allMigrations
        )

        journal[.lastCompletedAppVersionMigration] = try #require(
            testData.prevMigrationMarker?.string
        )

        // When
        try await sut.performAppMigrations()

        // Then
        #expect(migrationsPeformed == testData.migrationsExpectedToBeRun)
        #expect(journal[.lastCompletedAppVersionMigration] == testData.newMigrationMarker.string)
    }

    @Test("Interrupted migrations will be retried")
    func interruptedMigrationsWillBeRetried() async throws {
        // Given
        let currentVersion: SemanticVersion = "1.2.3"
        let sut = makeSUT(
            currentVersion: currentVersion,
            migrations: ["0.1.0", "0.2.0", "1.0.0", "1.2.3"]
        )

        journal[.lastCompletedAppVersionMigration] = "0.1.0"
        migrationToInterrupt = "1.0.0"

        // When
        let error = await #expect(throws: String.self) {
            try await sut.performAppMigrations()
        }

        // Then
        #expect(error == "Interrupted migration: 1.0.0")
        #expect(migrationsPeformed == ["0.2.0"])
        #expect(journal[.lastCompletedAppVersionMigration] == "0.2.0")

        // When
        migrationToInterrupt = nil
        migrationsPeformed = []
        try await sut.performAppMigrations()

        // Then
        #expect(migrationsPeformed == ["1.0.0", "1.2.3"])
        #expect(journal[.lastCompletedAppVersionMigration] == "1.2.3")
    }

}

extension AppVersionMigrationServiceTests {

    struct TestData: Sendable {

        let description: String
        let allMigrations: [SemanticVersion]
        var prevMigrationMarker: SemanticVersion?
        let currentVersion: SemanticVersion
        let migrationsExpectedToBeRun: [SemanticVersion]
        let newMigrationMarker: SemanticVersion

    }

    struct MockMigration: AppVersionMigration {

        let version: SemanticVersion
        let block: (SemanticVersion) async throws -> Void

        func perform() async throws {
            try await block(version)
        }

    }

}
