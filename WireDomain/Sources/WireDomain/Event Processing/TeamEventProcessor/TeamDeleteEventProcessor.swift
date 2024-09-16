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

import CoreData
import WireAPI
import WireDataModel

/// Process team delete events.

protocol TeamDeleteEventProcessorProtocol {

    /// Process a team delete event.

    func processEvent() async throws

}

struct TeamDeleteEventProcessor: TeamDeleteEventProcessorProtocol {

    let context: NSManagedObjectContext

    func processEvent() async throws {
        // swiftlint:disable:next todo_requires_jira_link
        // TODO: revisit this implementation
        let notification = AccountDeletedNotification(context: context)
        notification.post(in: context.notificationContext)
    }

}
