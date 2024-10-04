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

import WireAPI
import WireSystem

/// Process user properties delete events.

protocol UserPropertiesDeleteEventProcessorProtocol {

    /// Process a user properties delete event.
    ///
    /// - Parameter event: A user properties delete event.

    func processEvent(_ event: UserPropertiesDeleteEvent) async

}

struct UserPropertiesDeleteEventProcessor: UserPropertiesDeleteEventProcessorProtocol {

    let repository: any UserRepositoryProtocol

    func processEvent(_ event: UserPropertiesDeleteEvent) async {
        let userPropertyKey = UserProperty.Key(rawValue: event.key)

        guard let userPropertyKey else {
            return WireLogger.eventProcessing.error(
                "Unknown user property key: \(event.key)"
            )
        }

        await repository.deleteUserProperty(withKey: userPropertyKey)
    }

}
