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
import WireDataModel
import WireLogging

// sourcery: AutoMockable
public protocol ResetProteusSessionUseCaseProtocol {

    /// Resets the proteus session between the self client and the given client.
    ///
    /// The local session is deleted and the client is marked so that the other party's
    /// clients get notified about the reset. When such a notification is expected (i.e. there is
    /// a one-to-one conversation), the call only returns once the other clients have been notified,
    /// so callers can keep a loading indicator visible for the whole operation.
    ///
    /// Can be called several times without issues.
    func invoke(userClient: UserClient) async
}

public struct ResetProteusSessionUseCase: ResetProteusSessionUseCaseProtocol {

    private let syncContext: NSManagedObjectContext

    public init(syncContext: NSManagedObjectContext) {
        self.syncContext = syncContext
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

        let session: (id: ProteusSessionID, service: any ProteusServiceInterface)? = await context.perform {
            guard
                let client = (try? context.existingObject(with: objectID)) as? UserClient,
                !client.isSelfClient(),
                let sessionID = client.proteusSessionID,
                let proteusService = context.proteusService
            else {
                return nil
            }
            return (sessionID, proteusService)
        }

        guard let session else { return }

        do {
            try await session.service.deleteSession(id: session.id)
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

    private let lock = NSLock()
    private var continuation: CheckedContinuation<Void, Never>?
    private var didReset = false
    private var token: NSObjectProtocol?

    func start(observing client: UserClient) {
        token = UserClientChangeInfo.add(observer: self, for: client)
    }

    func waitUntilReset() async {
        await withCheckedContinuation { continuation in
            lock.lock()
            if didReset {
                lock.unlock()
                continuation.resume()
            } else {
                self.continuation = continuation
                lock.unlock()
            }
        }
    }

    func userClientDidChange(_ changeInfo: UserClientChangeInfo) {
        guard changeInfo.sessionHasBeenReset else { return }

        lock.lock()
        let continuation = continuation
        self.continuation = nil
        didReset = true
        token = nil
        lock.unlock()

        continuation?.resume()
    }
}
