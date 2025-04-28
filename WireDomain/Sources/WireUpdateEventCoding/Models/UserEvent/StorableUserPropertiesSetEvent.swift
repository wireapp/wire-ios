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

import Foundation
import WireAPI

struct StorableUserPropertiesSetEvent: Equatable, Codable {

    private let property: StorableUserProperty

    init(_ value: WireAPI.UserPropertiesSetEvent) {
        self.property = StorableUserProperty(value.property)
    }

    func toAPIModel() -> WireAPI.UserPropertiesSetEvent {
        .init(property: property.toAPIModel())
    }

}

private enum StorableUserProperty: Equatable, Codable {

    case areReadReceiptsEnabled(Bool)
    case areTypingIndicatorsEnabled(Bool)
    case conversationLabels([StorableConversationLabel])
    case unknown(key: String)

    init(_ value: WireAPI.UserProperty) {
        switch value {
        case let .areReadReceiptsEnabled(isEnabled):
            self = .areReadReceiptsEnabled(isEnabled)
        case let .areTypingIndicatorsEnabled(isEnabled):
            self = .areTypingIndicatorsEnabled(isEnabled)
        case let .conversationLabels(labels):
            self = .conversationLabels(
                labels.map {
                    StorableConversationLabel(
                        id: $0.id,
                        name: $0.name,
                        type: $0.type,
                        conversationIDs: $0.conversationIDs
                    )
                }
            )
        case let .unknown(key):
            self = .unknown(key: key)
        }
    }

    func toAPIModel() -> WireAPI.UserProperty {
        switch self {
        case let .areReadReceiptsEnabled(isEnabled):
            .areReadReceiptsEnabled(isEnabled)
        case let .areTypingIndicatorsEnabled(isEnabled):
            .areTypingIndicatorsEnabled(isEnabled)
        case let .conversationLabels(labels):
            .conversationLabels(
                labels.map {
                    WireAPI.ConversationLabel(
                        id: $0.id,
                        name: $0.name,
                        type: $0.type,
                        conversationIDs: $0.conversationIDs
                    )
                }
            )
        case let .unknown(key):
            .unknown(key: key)
        }
    }

}

private struct StorableConversationLabel: Equatable, Codable, Sendable {

    let id: UUID
    let name: String?
    let type: Int16
    let conversationIDs: [UUID]

}
