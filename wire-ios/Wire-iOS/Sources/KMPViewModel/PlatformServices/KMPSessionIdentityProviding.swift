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

struct KMPAccountIdentity: Equatable, Hashable, Sendable {

    let userID: String
    let domain: String?
    let clientID: String?
    let teamID: String?

    init(
        userID: String,
        domain: String? = nil,
        clientID: String? = nil,
        teamID: String? = nil
    ) {
        self.userID = userID
        self.domain = domain
        self.clientID = clientID
        self.teamID = teamID
    }
}

struct KMPSessionIdentity: Equatable, Hashable, Sendable {

    let account: KMPAccountIdentity
    let sessionID: String?

    init(
        account: KMPAccountIdentity,
        sessionID: String? = nil
    ) {
        self.account = account
        self.sessionID = sessionID
    }
}

protocol KMPSessionIdentityProviding {
    var currentSessionIdentity: KMPSessionIdentity? { get }
}

struct AnyKMPSessionIdentityProvider: KMPSessionIdentityProviding {

    private let resolveCurrentSessionIdentity: () -> KMPSessionIdentity?

    init<Provider: KMPSessionIdentityProviding>(_ provider: Provider) {
        self.resolveCurrentSessionIdentity = { provider.currentSessionIdentity }
    }

    init(currentSessionIdentity: @escaping () -> KMPSessionIdentity?) {
        self.resolveCurrentSessionIdentity = currentSessionIdentity
    }

    var currentSessionIdentity: KMPSessionIdentity? {
        resolveCurrentSessionIdentity()
    }
}
