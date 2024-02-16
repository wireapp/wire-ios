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
import WireRequestStrategy

final class EvaluateOneOnOneConversationsStrategy: AbstractRequestStrategy {

    let syncPhase: SyncPhase = .evaluate1on1ConversationsForMLS

    private unowned var syncStatus: SyncProgress

    private var isSyncing: Bool { syncStatus.currentSyncPhase == syncPhase }

    private var task: Task<Void, Never>?

    var taskCompletion: (() -> Void)?

    public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        syncStatus: SyncProgress
    ) {
        self.syncStatus = syncStatus

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
    }

    deinit {
        task?.cancel()
    }

    override func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard isSyncing, task == nil else {
            return nil
        }

        WireLogger.conversation.info("EvaluateOneOnOneConversationsStrategy: start evaluate one on one conversations!")

        precondition(managedObjectContext.zm_isSyncContext, "can only execute on syncContext!")
        let syncContext = managedObjectContext

        // store task to avoid duplicated entries and concurrency issues
        task = Task { [weak self] in
            guard let self else {
                assertionFailure("EvaluateOneOnOneConversationsStrategy: cannot perform without self reference!")
                return
            }

            do {
                let resolver = OneOnOneResolver(syncContext: syncContext)
                try await resolver.resolveAllOneOnOneConversations(in: syncContext)

                await syncContext.perform {
                    self.finishCurrentSyncPhase()
                }
            } catch {
                await syncContext.perform {
                    self.failCurrentSyncPhase(errorMessage: "EvaluateOneOnOneConversationsStrategy: failed to resolve all 1-1 conversations!")
                }
            }

            self.task = nil
            self.taskCompletion?()
        }

        return nil
    }

    private func failCurrentSyncPhase(errorMessage: String) {
        WireLogger.conversation.error("EvaluateOneOnOneConversationsStrategy: \(errorMessage)!")
        syncStatus.failCurrentSyncPhase(phase: syncPhase)
    }

    private func finishCurrentSyncPhase() {
        WireLogger.conversation.error("EvaluateOneOnOneConversationsStrategy: finishCurrentSyncPhase!")
        syncStatus.finishCurrentSyncPhase(phase: syncPhase)
    }
}
