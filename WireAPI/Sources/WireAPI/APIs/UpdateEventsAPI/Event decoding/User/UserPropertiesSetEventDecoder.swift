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

struct UserPropertiesSetEventDecoder {

    func decode(
        from container: KeyedDecodingContainer<UserEventCodingKeys>
    ) throws -> UserPropertiesSetEvent {
        let property: UserProperty
        let key = try container.decode(
            String.self,
            forKey: .propertyKey
        )

        let userPropertyKey = UserProperty.Key(rawValue: key)

        switch userPropertyKey {
        case .wireReceiptMode:
            let value = try container.decode(
                Int.self,
                forKey: .propertyValue
            )

            property = .areReadReceiptsEnabled(value == 1)

        case .wireTypingIndicatorMode:
            let value = try container.decode(
                Int.self,
                forKey: .propertyValue
            )

            property = .areTypingIndicatorsEnabled(value == 1)

        case .labels:
            let payload = try container.decode(
                LabelsPayload.self,
                forKey: .propertyValue
            )

            let conversationLabels = payload.labels.map {
                ConversationLabel(
                    id: $0.id,
                    name: $0.name,
                    type: $0.type,
                    conversationIDs: $0.conversations
                )
            }

            property = .conversationLabels(conversationLabels)

        default:
            property = .unknown(key: key)
        }

        return UserPropertiesSetEvent(property: property)
    }

}

struct LabelsPayload: Decodable {

    let labels: [Label]

    struct Label: Decodable {

        let id: UUID
        let type: Int16
        let name: String?
        let conversations: [UUID]

    }

}
