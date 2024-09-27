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

// MARK: - AVSClient

/// Used to identify a participant in a call.

public struct AVSClient: Hashable {
    // MARK: Lifecycle

    init?(userClient: UserClient) {
        guard
            let userId = userClient.user?.avsIdentifier,
            let clientId = userClient.remoteIdentifier
        else {
            return nil
        }

        self.init(
            userId: userId,
            clientId: clientId
        )
    }

    public init?(member: MLSConferenceInfo.Member) {
        guard let userID = UUID(uuidString: member.id.userID) else {
            return nil
        }

        let avsID = AVSIdentifier(
            identifier: userID,
            domain: member.id.domain
        )

        self.init(
            userId: avsID,
            clientId: member.id.clientID,
            isMemberOfSubconversation: member.isInSubconversation
        )
    }

    public init(
        userId: AVSIdentifier,
        clientId: String,
        isMemberOfSubconversation: Bool = false
    ) {
        self.userId = userId.serialized
        self.clientId = clientId
        self.isMemberOfSubconversation = isMemberOfSubconversation
    }

    // MARK: Public

    public let userId: String
    public let clientId: String
    public var isMemberOfSubconversation = false
}

// MARK: Codable

extension AVSClient: Codable {
    enum CodingKeys: String, CodingKey {
        case userId = "userid"
        case clientId = "clientid"
        case isMemberOfSubconversation = "in_subconv"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.clientId = try container.decode(String.self, forKey: .clientId)
        self.isMemberOfSubconversation = try container
            .decodeIfPresent(Bool.self, forKey: .isMemberOfSubconversation) ?? false
    }
}

extension AVSClient {
    public var avsIdentifier: AVSIdentifier {
        AVSIdentifier.from(string: userId)
    }
}
