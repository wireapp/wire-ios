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

struct StorableTeamCreateEvent: Equatable, Codable, Sendable {

    private let identifier: UUID
    private let name: String
    private let creator: UUID
    private let icon: String
    private let iconKey: String?
    private let splashScreen: String?

    init(_ value: WireNetwork.TeamCreateEvent) {
        self.identifier = value.identifier
        self.name = value.name
        self.creator = value.creator
        self.icon = value.icon
        self.iconKey = value.iconKey
        self.splashScreen = value.splashScreen
    }

    func toAPIModel() -> WireNetwork.TeamCreateEvent {
        .init(
            identifier: identifier,
            name: name,
            creator: creator,
            icon: icon,
            iconKey: iconKey,
            splashScreen: splashScreen
        )
    }

}
