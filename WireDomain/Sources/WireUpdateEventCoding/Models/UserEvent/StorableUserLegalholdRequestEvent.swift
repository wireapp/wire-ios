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
import WireNetwork

struct StorableUserLegalholdRequestEvent: Equatable, Codable, Sendable {

    private let userID: UUID
    private let clientID: String
    private let lastPrekey: Prekey

    init(_ value: WireNetwork.UserLegalholdRequestEvent) {
        self.userID = value.userID
        self.clientID = value.clientID
        self.lastPrekey = Prekey(id: value.lastPrekey.id, base64EncodedKey: value.lastPrekey.base64EncodedKey)
    }

    func toAPIModel() -> WireNetwork.UserLegalholdRequestEvent {
        .init(
            userID: userID,
            clientID: clientID,
            lastPrekey: WireNetwork.Prekey(
                id: lastPrekey.id,
                base64EncodedKey: lastPrekey.base64EncodedKey
            )
        )
    }

}

private struct Prekey: Equatable, Codable, Sendable {

    let id: Int
    let base64EncodedKey: String

}
