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

public final class SelfUserRequestStrategy: AbstractRequestStrategy {
    // MARK: - Properties

    private let actionSync: EntityActionSync

    // MARK: - Life cycle

    override public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus
    ) {
        self.actionSync =
            EntityActionSync(actionHandlers: [PushSupportedProtocolsActionHandler(context: managedObjectContext)])

        super.init(
            withManagedObjectContext: managedObjectContext,
            applicationStatus: applicationStatus
        )
    }

    // MARK: - Request

    override public func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        actionSync.nextRequest(for: apiVersion)
    }
}
