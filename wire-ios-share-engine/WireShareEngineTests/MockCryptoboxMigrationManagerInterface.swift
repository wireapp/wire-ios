//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

// swiftlint:disable all

import Foundation
import WireDataModel

public class MockCryptoboxMigrationManagerInterface: CryptoboxMigrationManagerInterface {

    // MARK: - Life cycle

    public init() {}

    // MARK: - isMigrationNeeded

    public var isMigrationNeededAccountDirectory_Invocations: [URL] = []
    public var isMigrationNeededAccountDirectory_MockMethod: ((URL) -> Bool)?
    public var isMigrationNeededAccountDirectory_MockValue: Bool?

    public func isMigrationNeeded(accountDirectory: URL) -> Bool {
        isMigrationNeededAccountDirectory_Invocations.append(accountDirectory)

        if let mock = isMigrationNeededAccountDirectory_MockMethod {
            return mock(accountDirectory)
        } else if let mock = isMigrationNeededAccountDirectory_MockValue {
            return mock
        } else {
            fatalError("no mock for `isMigrationNeededAccountDirectory`")
        }
    }

    // MARK: - performMigration

    public var performMigrationAccountDirectorySyncContext_Invocations: [(accountDirectory: URL, syncContext: NSManagedObjectContext)] = []
    public var performMigrationAccountDirectorySyncContext_MockError: Error?
    public var performMigrationAccountDirectorySyncContext_MockMethod: ((URL, NSManagedObjectContext) throws -> Void)?

    public func performMigration(accountDirectory: URL, syncContext: NSManagedObjectContext) throws {
        performMigrationAccountDirectorySyncContext_Invocations.append((accountDirectory: accountDirectory, syncContext: syncContext))

        if let error = performMigrationAccountDirectorySyncContext_MockError {
            throw error
        }

        guard let mock = performMigrationAccountDirectorySyncContext_MockMethod else {
            fatalError("no mock for `performMigrationAccountDirectorySyncContext`")
        }

        try mock(accountDirectory, syncContext)
    }

    // MARK: - completeMigration

    public var completeMigrationSyncContext_Invocations: [NSManagedObjectContext] = []
    public var completeMigrationSyncContext_MockError: Error?
    public var completeMigrationSyncContext_MockMethod: ((NSManagedObjectContext) throws -> Void)?

    public func completeMigration(syncContext: NSManagedObjectContext) throws {
        completeMigrationSyncContext_Invocations.append(syncContext)

        if let error = completeMigrationSyncContext_MockError {
            throw error
        }

        guard let mock = completeMigrationSyncContext_MockMethod else {
            fatalError("no mock for `completeMigrationSyncContext`")
        }

        try mock(syncContext)
    }

}

