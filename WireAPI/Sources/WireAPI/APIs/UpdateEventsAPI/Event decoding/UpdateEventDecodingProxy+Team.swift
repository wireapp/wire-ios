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

extension UpdateEventDecodingProxy {

    init(
        eventType: TeamEventType,
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(keyedBy: TeamEventCodingKeys.self)

        switch eventType {
        case .delete:
            updateEvent = .team(.delete)

        case .memberLeave:
            let event = try TeamMemberLeaveEventDecoder().decode(from: container)
            updateEvent = .team(.memberLeave(event))

        case .memberUpdate:
            let event = try TeamMemberUpdateEventDecoder().decode(from: container)
            updateEvent = .team(.memberUpdate(event))
        }
    }
}
