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

enum StorableUpdateEvent: Equatable, Codable, Sendable {

    case conversation(StorableConversationEvent)
    case featureConfig(StorableFeatureConfigEvent)
    case federation(StorableFederationEvent)
    case user(StorableUserEvent)
    case team(StorableTeamEvent)
    case unknown(eventType: String)

    init(_ value: WireNetwork.UpdateEvent) {
        switch value {
        case let .conversation(conversation):
            self = .conversation(StorableConversationEvent(conversation))
        case let .featureConfig(featureConfig):
            self = .featureConfig(StorableFeatureConfigEvent(featureConfig))
        case let .federation(federation):
            self = .federation(StorableFederationEvent(federation))
        case let .user(user):
            self = .user(StorableUserEvent(user))
        case let .team(team):
            self = .team(StorableTeamEvent(team))
        case let .unknown(eventType):
            self = .unknown(eventType: eventType)
        }
    }

    func toAPIModel() -> WireNetwork.UpdateEvent {
        switch self {
        case let .conversation(conversation):
            .conversation(conversation.toAPIModel())
        case let .featureConfig(featureConfig):
            .featureConfig(featureConfig.toAPIModel())
        case let .federation(federation):
            .federation(federation.toAPIModel())
        case let .user(user):
            .user(user.toAPIModel())
        case let .team(team):
            .team(team.toAPIModel())
        case let .unknown(eventType):
            .unknown(eventType: eventType)
        }
    }

}
