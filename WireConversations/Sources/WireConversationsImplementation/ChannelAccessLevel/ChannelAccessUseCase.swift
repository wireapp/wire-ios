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
package import WireConversationsAPI

package protocol ChannelAccessUseCaseProtocol {
    var settings: ChannelAccessSettings { get }
    func updateAccessLevel(to level: ChannelAccessLevel)
    func updateParticipantPermission(to permission: ChannelAccessLevelPermission)
}

package class ChannelAccessUseCase: ChannelAccessUseCaseProtocol {

    public var settings: ChannelAccessSettings

    public init(permission: ChannelAccessLevelPermission?) {
        let settings = ChannelAccessSettings(
            accessLevel: permission == nil ? .public : .private,
            participantPermission: permission
        )

        self.settings = settings
    }

    public func updateAccessLevel(to level: ChannelAccessLevel) {
        settings.accessLevel = level
    }

    public func updateParticipantPermission(to permission: ChannelAccessLevelPermission) {
        settings.participantPermission = permission
    }
}
