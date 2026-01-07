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
import WireLogging

public final class FetchBackendMLSPublicKeysRequestStrategy: AbstractRequestStrategy {

    // Action

    private let actionHandler: FetchBackendMLSPublicKeysActionHandler
    private let actionSync: EntityActionSync

    // MARK: - Life cycle

    public override init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus
    ) {
        // TODO: only used on MLSActionsProvider and ZMClientRegistrationStatus
        self.actionHandler = FetchBackendMLSPublicKeysActionHandler(context: managedObjectContext)
        self.actionSync = EntityActionSync(actionHandlers: [actionHandler])

        super.init(
            withManagedObjectContext: managedObjectContext,
            applicationStatus: applicationStatus
        )

        configuration = [
            .allowsRequestsWhileUnauthenticated,
            .allowsRequestsWhileOnline,
            .allowsRequestsDuringQuickSync,
            .allowsRequestsDuringSlowSync,
            .allowsRequestsWhileWaitingForWebsocket,
            .allowsRequestsWhileInBackground
        ]
    }

    // MARK: - Request

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        actionSync.nextRequest(for: apiVersion)
    }
}
