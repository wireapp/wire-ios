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

struct StorableUserConnectionEvent: Equatable, Codable, Sendable {

    private let userName: String?
    private let connection: StorableConnection

    init(_ value: WireNetwork.UserConnectionEvent) {
        self.userName = value.userName
        self.connection = StorableConnection(
            senderID: value.connection.senderID,
            receiverID: value.connection.receiverID,
            receiverQualifiedID: value.connection.receiverQualifiedID.map(StorableQualifiedID.init),
            conversationID: value.connection.conversationID,
            qualifiedConversationID: value.connection.qualifiedConversationID.map(StorableQualifiedID.init),
            lastUpdate: value.connection.lastUpdate,
            status: StorableConnectionStatus(value.connection.status)
        )
    }

    func toAPIModel() -> WireNetwork.UserConnectionEvent {
        .init(
            userName: userName,
            connection: .init(
                senderID: connection.senderID,
                receiverID: connection.receiverID,
                receiverQualifiedID: connection.receiverQualifiedID?.toAPIModel(),
                conversationID: connection.conversationID,
                qualifiedConversationID: connection.qualifiedConversationID?.toAPIModel(),
                lastUpdate: connection.lastUpdate,
                status: connection.status.toAPIModel()
            )
        )
    }

}

private struct StorableConnection: Equatable, Codable, Sendable {

    let senderID: UUID?
    let receiverID: UUID?
    let receiverQualifiedID: StorableQualifiedID?
    let conversationID: UUID?
    let qualifiedConversationID: StorableQualifiedID?
    let lastUpdate: Date
    let status: StorableConnectionStatus

}

private enum StorableConnectionStatus: String, Codable, Equatable, Sendable {

    case accepted
    case blocked
    case pending
    case ignored
    case sent
    case cancelled
    case missingLegalholdConsent

    init(_ value: WireNetwork.ConnectionStatus) {
        switch value {
        case .accepted:
            self = .accepted
        case .blocked:
            self = .blocked
        case .pending:
            self = .pending
        case .ignored:
            self = .ignored
        case .sent:
            self = .sent
        case .cancelled:
            self = .cancelled
        case .missingLegalholdConsent:
            self = .missingLegalholdConsent
        }
    }

    func toAPIModel() -> WireNetwork.ConnectionStatus {
        switch self {
        case .accepted:
            .accepted
        case .blocked:
            .blocked
        case .pending:
            .pending
        case .ignored:
            .ignored
        case .sent:
            .sent
        case .cancelled:
            .cancelled
        case .missingLegalholdConsent:
            .missingLegalholdConsent
        }
    }

}
