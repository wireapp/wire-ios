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

import WireDataModel
import WireLogging
import WireNetwork

/// Observes pending events, process them and generates new notifications content.
struct VerifyUserSessionUseCase {

    enum Constants {
        static let cookieName = "zuid"
    }

    // MARK: - Error

    enum Failure: Error {
        case coreDataMissingSharedContainer
        case coreDataMigrationRequired
        case syncV2IsNotEnabled
        case unableToLoadStores(Error)
        case userUnauthenticated
    }

    // MARK: - Properties

    private let journal: any JournalProtocol
    private let cookieStorage: any CookieStorageProtocol
    private let coreData: any CoreDataStackProtocol
    private let logger = WireLogger.notifications

    init(
        journal: any JournalProtocol,
        cookieStorage: any CookieStorageProtocol,
        coreData: any CoreDataStackProtocol
    ) {
        self.journal = journal
        self.cookieStorage = cookieStorage
        self.coreData = coreData
    }

    /// Ensures user is properly authenticated.

    func invoke() async throws {
        guard journal[.isSyncV2Enabled] else {
            throw Failure.syncV2IsNotEnabled
        }

        guard try await isAuthenticated() else {
            throw Failure.userUnauthenticated
        }

        try await setupCoreData()
    }

    private func isAuthenticated() async throws -> Bool {
        logger.info(
            "Verifying whether user is authenticated..",
            attributes: .newNSE
        )

        let cookies = try await cookieStorage.fetchCookies()

        for cookie in cookies where cookie.name == Constants.cookieName {
            if let cookieExpirationDate = cookie.expiresDate {
                return cookieExpirationDate > .now
            } else {
                return false
            }
        }

        return false // no cookies found
    }

    /// Setup core data stores and its dependencies.
    private func setupCoreData() async throws {
        guard coreData.storesExists else {
            throw Failure.coreDataMissingSharedContainer
        }

        guard !coreData.needsMigration  else {
            throw Failure.coreDataMigrationRequired
        }

        do {
            try await coreData.load()
        } catch {
            throw Failure.unableToLoadStores(error)
        }
    }
}
