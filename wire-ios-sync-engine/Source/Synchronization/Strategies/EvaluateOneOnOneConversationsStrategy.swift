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

final class EvaluateOneOnOneConversationsStrategy: AbstractRequestStrategy {

    let syncPhase: SyncPhase = .evaluate1on1ConversationsForMLS

    private unowned var syncStatus: SyncStatus

    private var isSyncing: Bool { syncStatus.currentSyncPhase == syncPhase }

    public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        syncStatus: SyncStatus
    ) {
        self.syncStatus = syncStatus

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
    }

    override func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        if isSyncing {
            // TODO: [WPB-5812] epic implementation
            // - Produce a list of the users we have 1:1 conversations with
            // - Loop through the list and evaluate the 1:1 conversation for each user.

            Task {
                guard let syncContext = await managedObjectContext.perform({ self.managedObjectContext.zm_sync }) else {
                    assertionFailure("can not perform strategy without sync context!")
                    return
                }

                do {
                    let resolver = OneOnOneResolver(syncContext: syncContext)
                    try await resolver.resolveAllOneOnOneConversations(in: syncContext)
                } catch {
                    // TODO: [WPB-111] add proper logging
                    debugPrint("failed to resolve all 1-1 conversations!")
                }

                // TODO: [WPB-111] test if this needs to be called on main actor?
                syncStatus.finishCurrentSyncPhase(phase: syncPhase)
            }

        }

        return nil
    }
}
