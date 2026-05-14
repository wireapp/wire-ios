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

public struct KaliumSessionStorageConfiguration: Equatable {

    public let appGroupContainerURL: URL
    public let accountUUID: UUID
    public let userId: String
    public let domain: String
    public let clientId: String
    public let legacyAccountDirectory: URL
    public let coreDataStoreURL: URL
    public let eventStoreURL: URL
    public let legacyCoreCryptoOpenInPlacePath: String
    public let kaliumRootPath: String
    public let suggestedKaliumSQLDelightStoragePath: String
    public let suggestedKaliumSQLDelightDatabasePath: String
}

public enum KaliumSessionStorageConfigurationFactory {

    public static func make(
        appGroupContainerURL: URL,
        accountUUID: UUID,
        userId: String,
        domain: String,
        clientId: String
    ) -> KaliumSessionStorageConfiguration {
        let legacyAccountDirectory = CoreDataStack.accountDataFolder(
            accountIdentifier: accountUUID,
            applicationContainer: appGroupContainerURL
        )
        let coreDataStoreURL = legacyAccountDirectory.appendingPersistentStoreLocation()
        let eventStoreURL = legacyAccountDirectory.appendingEventStoreLocation()
        let legacyCoreCryptoOpenInPlacePath = CoreCryptoConfigProvider
            .legacyCoreCryptoOpenInPlaceDirectory(legacyAccountDirectory: legacyAccountDirectory)
            .path

        let kaliumRootURL = appGroupContainerURL.appendingPathComponent("Kalium", isDirectory: true)
        let sqlDelightStorageURL = kaliumRootURL
            .appendingPathComponent(domain, isDirectory: true)
            .appendingPathComponent(userId, isDirectory: true)
            .appendingPathComponent("storage", isDirectory: true)
        let sqlDelightDatabaseURL = sqlDelightStorageURL
            .appendingPathComponent("user-db-\(userId)-\(domain)")

        return KaliumSessionStorageConfiguration(
            appGroupContainerURL: appGroupContainerURL,
            accountUUID: accountUUID,
            userId: userId,
            domain: domain,
            clientId: clientId,
            legacyAccountDirectory: legacyAccountDirectory,
            coreDataStoreURL: coreDataStoreURL,
            eventStoreURL: eventStoreURL,
            legacyCoreCryptoOpenInPlacePath: legacyCoreCryptoOpenInPlacePath,
            kaliumRootPath: kaliumRootURL.path,
            suggestedKaliumSQLDelightStoragePath: sqlDelightStorageURL.path,
            suggestedKaliumSQLDelightDatabasePath: sqlDelightDatabaseURL.path
        )
    }
}
