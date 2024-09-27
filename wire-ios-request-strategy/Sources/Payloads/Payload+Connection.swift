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

extension Payload {
    enum ConnectionStatus: String, Codable, CaseIterable {
        case accepted
        case blocked
        case pending
        case ignored
        case sent
        case cancelled
        case missingLegalholdConsent = "missing-legalhold-consent"

        // MARK: Lifecycle

        init?(_ status: ZMConnectionStatus) {
            switch status {
            case .invalid:
                return nil
            case .accepted:
                self = .accepted
            case .pending:
                self = .pending
            case .ignored:
                self = .ignored
            case .blocked:
                self = .blocked
            case .sent:
                self = .sent
            case .cancelled:
                self = .cancelled
            case .blockedMissingLegalholdConsent:
                self = .missingLegalholdConsent
            @unknown default:
                return nil
            }
        }

        // MARK: Internal

        var internalStatus: ZMConnectionStatus {
            switch self {
            case .sent:
                .sent
            case .accepted:
                .accepted
            case .pending:
                .pending
            case .blocked:
                .blocked
            case .cancelled:
                .cancelled
            case .ignored:
                .ignored
            case .missingLegalholdConsent:
                .blockedMissingLegalholdConsent
            }
        }
    }

    struct Connection: Codable, EventData {
        enum CodingKeys: String, CodingKey {
            case from
            case to
            case qualifiedTo = "qualified_to"
            case conversationID = "conversation"
            case qualifiedConversationID = "qualified_conversation"
            case lastUpdate = "last_update"
            case status
        }

        static var eventType: ZMUpdateEventType {
            .userConnection
        }

        let from: UUID?
        let to: UUID?
        let qualifiedTo: QualifiedID?
        let conversationID: UUID?
        let qualifiedConversationID: QualifiedID?
        let lastUpdate: Date
        let status: ConnectionStatus
    }

    struct ConnectionUpdate: Codable {
        let status: ConnectionStatus
    }

    struct ConnectionRequest: Codable {
        enum CodingKeys: String, CodingKey {
            case userID = "user"
            case name
        }

        let userID: UUID
        let name: String
    }

    struct PaginatedLocalConnectionList: Codable, Paginatable {
        enum CodingKeys: String, CodingKey {
            case connections
            case hasMore = "has_more"
        }

        let connections: [Connection]
        let hasMore: Bool

        var nextStartReference: String? {
            connections.last?.to?.transportString()
        }
    }

    struct PaginatedConnectionList: Codable, Paginatable {
        enum CodingKeys: String, CodingKey {
            case connections
            case pagingState = "paging_state"
            case hasMore = "has_more"
        }

        let connections: [Connection]
        let pagingState: String
        let hasMore: Bool

        var nextStartReference: String? {
            pagingState
        }
    }

    struct UserConnectionEvent: Codable {
        enum CodingKeys: String, CodingKey {
            case connection
            case type
        }

        let connection: Connection
        let type: String
    }
}
