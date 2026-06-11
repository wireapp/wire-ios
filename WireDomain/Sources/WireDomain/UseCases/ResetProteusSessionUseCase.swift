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
import os
import WireDataModel
import WireLogging

// sourcery: AutoMockable
public protocol ResetProteusSessionUseCaseProtocol {

    /// Resets the proteus session between the self client and the given client.
    ///
    /// The local session is deleted and the client is marked so that the other party's
    /// clients get notified about the reset.
    func invoke(userClient: UserClient) async
}

public struct ResetProteusSessionUseCase: ResetProteusSessionUseCaseProtocol {

    private let syncContext: NSManagedObjectContext
    private let proteusService: any ProteusServiceInterface

    public init(
        syncContext: NSManagedObjectContext,
        proteusService: any ProteusServiceInterface
    ) {
        self.syncContext = syncContext
        self.proteusService = proteusService
    }

    public func invoke(userClient: UserClient) async {
        let objectID = userClient.objectID

        await deleteProteusSession(objectID: objectID)

        // Only wait for the "other clients notified" signal when there is a one-to-one
        // conversation to send the reset message to. Otherwise `ResetSessionRequestStrategy`
        // returns early and the flag is never cleared, which would block the caller forever.
        let shouldWaitForNotification = await userClient.managedObjectContext?.perform {
            userClient.user?.oneToOneConversation != nil
        } ?? false

        guard shouldWaitForNotification else {
            await markNeedsToNotifyOtherClients(objectID: objectID)
            return
        }

        let observer = SessionResetObserver()
        observer.start(observing: userClient)
        await markNeedsToNotifyOtherClients(objectID: objectID)
        await observer.waitUntilReset()
    }

    // MARK: - Private

    private func deleteProteusSession(objectID: NSManagedObjectID) async {
        let context = syncContext

        let sessionID: ProteusSessionID? = await context.perform {
            guard
                let client = (try? context.existingObject(with: objectID)) as? UserClient,
                !client.isSelfClient()
            else {
                return nil
            }
            return client.proteusSessionID
        }

        guard let sessionID else { return }

        do {
            try await proteusService.deleteSession(id: sessionID)
        } catch {
            WireLogger.proteus.error("Failed to delete session while resetting: \(error)")
        }
    }

    private func markNeedsToNotifyOtherClients(objectID: NSManagedObjectID) async {
        let context = syncContext

        await context.perform {
            guard let client = (try? context.existingObject(with: objectID)) as? UserClient else {
                return
            }
            // Marking the client triggers `ResetSessionRequestStrategy` to notify the other party.
            client.needsToNotifyOtherUserAboutSessionReset = true
            context.saveOrRollback()
        }
    }
}

// MARK: - SessionResetObserver

/// Bridges the `UserClientChangeInfo` observation to async/await, resuming once the other
/// user's clients have been notified about the session reset (i.e. `sessionHasBeenReset`).
private final class SessionResetObserver: NSObject, UserClientObserver {

    private let lock = OSAllocatedUnfairLock()
    private var continuation: CheckedContinuation<Void, Never>?
    private var didReset = false
    private var token: NSObjectProtocol?

    func start(observing client: UserClient) {
        token = UserClientChangeInfo.add(observer: self, for: client)
    }

    func waitUntilReset() async {
        await withCheckedContinuation { continuation in
            let alreadyReset = lock.withLock {
                if didReset { return true }
                self.continuation = continuation
                return false
            }
            if alreadyReset { continuation.resume() }
        }
    }

    func userClientDidChange(_ changeInfo: UserClientChangeInfo) {
        guard changeInfo.sessionHasBeenReset else { return }

        let continuation = lock.withLock { () -> CheckedContinuation<Void, Never>? in
            let continuation = self.continuation
            self.continuation = nil
            didReset = true
            token = nil
            return continuation
        }

        continuation?.resume()
    }
}
