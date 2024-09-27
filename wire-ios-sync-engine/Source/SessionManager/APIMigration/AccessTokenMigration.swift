//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import struct WireSystem.WireLogger

// MARK: - AccessTokenRenewalObserver

protocol AccessTokenRenewalObserver {
    func accessTokenRenewalDidSucceed()
    func accessTokenRenewalDidFail()
}

// MARK: - AccessTokenRenewing

protocol AccessTokenRenewing {
    func setAccessTokenRenewalObserver(_ observer: AccessTokenRenewalObserver)
    func renewAccessToken(with clientID: String)
}

// MARK: - AccessTokenMigration

class AccessTokenMigration: APIMigration, AccessTokenRenewalObserver {
    // MARK: Internal

    enum Error: Swift.Error {
        case failedToRenewAccessToken
    }

    let version: APIVersion = .v3

    func perform(with session: ZMUserSession, clientID: String) async throws {
        try await perform(withTokenRenewer: session, clientID: clientID)
    }

    func perform(withTokenRenewer tokenRenewer: AccessTokenRenewing, clientID: String) async throws {
        WireLogger.apiMigration.info("performing access token migration for clientID \(clientID)")

        tokenRenewer.setAccessTokenRenewalObserver(self)

        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<
            Void,
            Swift.Error
        >) in
            self?.continuation = continuation
            tokenRenewer.renewAccessToken(with: clientID)
        }
    }

    func accessTokenRenewalDidSucceed() {
        WireLogger.apiMigration.info("successfully renewed access token")
        continuation?.resume()
        teardownContinuation()
    }

    func accessTokenRenewalDidFail() {
        WireLogger.apiMigration.warn("failed to renew access token")
        continuation?.resume(throwing: Self.Error.failedToRenewAccessToken)
        teardownContinuation()
    }

    // MARK: Private

    private var continuation: CheckedContinuation<Void, Swift.Error>?

    private func teardownContinuation() {
        continuation = nil
    }
}
