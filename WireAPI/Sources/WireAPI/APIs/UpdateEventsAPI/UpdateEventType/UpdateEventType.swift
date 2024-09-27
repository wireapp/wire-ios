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

enum UpdateEventType {
    case conversation(ConversationEventType)
    case featureConfig(FeatureConfigEventType)
    case federation(FederationEventType)
    case user(UserEventType)
    case team(TeamEventType)
    case unknown(String)

    // MARK: Lifecycle

    init(_ string: String) {
        if let eventType = ConversationEventType(rawValue: string) {
            self = .conversation(eventType)
        } else if let eventType = FeatureConfigEventType(rawValue: string) {
            self = .featureConfig(eventType)
        } else if let eventType = FederationEventType(rawValue: string) {
            self = .federation(eventType)
        } else if let eventType = UserEventType(rawValue: string) {
            self = .user(eventType)
        } else if let eventType = TeamEventType(rawValue: string) {
            self = .team(eventType)
        } else {
            self = .unknown(string)
        }
    }
}
