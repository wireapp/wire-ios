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
import WireDataModel

/// A class responsible for setting up action handlers for MLS requests
/// and for notifying them when a request is allowed.

public final class MLSRequestStrategy: AbstractRequestStrategy {
    // MARK: Lifecycle

    override public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus
    ) {
        self.entitySync = EntityActionSync(actionHandlers: [
            SendMLSMessageActionHandler(context: managedObjectContext),
            SendCommitBundleActionHandler(context: managedObjectContext),
            CountSelfMLSKeyPackagesActionHandler(context: managedObjectContext),
            UploadSelfMLSKeyPackagesActionHandler(context: managedObjectContext),
            ClaimMLSKeyPackageActionHandler(context: managedObjectContext),
            FetchBackendMLSPublicKeysActionHandler(context: managedObjectContext),
            FetchMLSSubconversationGroupInfoActionHandler(context: managedObjectContext),
            FetchMLSConversationGroupInfoActionHandler(context: managedObjectContext),
            FetchSubgroupActionHandler(context: managedObjectContext),
            DeleteSubgroupActionHandler(context: managedObjectContext),
            LeaveSubconversationActionHandler(context: managedObjectContext),
            ReplaceSelfMLSKeyPackagesActionHandler(context: managedObjectContext),
            FetchSupportedProtocolsActionHandler(context: managedObjectContext),
            SyncMLSOneToOneConversationActionHandler(context: managedObjectContext),
        ])

        super.init(
            withManagedObjectContext: managedObjectContext,
            applicationStatus: applicationStatus
        )

        configuration = [
            .allowsRequestsDuringSlowSync,
            .allowsRequestsWhileOnline,
            .allowsRequestsDuringQuickSync,
            .allowsRequestsWhileWaitingForWebsocket,
        ]
    }

    // MARK: Public

    // MARK: - Requests

    override public func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        entitySync.nextRequest(for: apiVersion)
    }

    // MARK: Private

    // MARK: - Properties

    private let entitySync: EntityActionSync
}
