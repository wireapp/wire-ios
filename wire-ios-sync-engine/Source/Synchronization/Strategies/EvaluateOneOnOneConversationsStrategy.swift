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

    private let syncPhase: SyncPhase = .evaluate1on1ConversationsForMLS

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
            debugPrint("EvaluateOneOnOneConversationsStrategy executed")
            syncStatus.finishCurrentSyncPhase(phase: syncPhase)
        }

        return nil
    }
}
