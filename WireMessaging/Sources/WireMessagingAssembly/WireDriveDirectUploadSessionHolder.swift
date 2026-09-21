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

public import Foundation
import os
import WireLogging
import WireMessagingData

/// Owns the background upload sessions for the lifetime of the process.
///
/// Held by the app target since a background `URLSession` must be a per-process singleton per identifier, but
/// `handleEventsForBackgroundURLSession` can fire before any account is loaded.
///
/// Lock-based rather than an actor so the app delegate can claim a session identifier
/// synchronously within iOS's short background-launch window.

public final class WireDriveDirectUploadSessionHolder: Sendable {

    enum Identifier {

        static let prefix = "com.wire.drive.upload"

        static func make(userID: UUID) -> String {
            "\(prefix)-\(userID.uuidString.lowercased())"
        }

        static func isDriveUploadSession(_ identifier: String) -> Bool {
            identifier.hasPrefix("\(prefix)-")
        }

        static func userID(from identifier: String) -> UUID? {
            guard isDriveUploadSession(identifier) else { return nil }
            let suffix = identifier.dropFirst(prefix.count + 1)
            return UUID(uuidString: String(suffix))
        }
    }

    private struct State {
        var sessions: [String: any WireDriveDirectUploadSessionProtocol] = [:]
        var completionHandlers: [String: @Sendable () -> Void] = [:]
    }

    private let lock = OSAllocatedUnfairLock<State>(initialState: .init())
    private let sharedContainerIdentifier: String?
    private let makeSession: @Sendable (String, String?) -> any WireDriveDirectUploadSessionProtocol

    /// - Parameter sharedContainerIdentifier: The app group container identifier. Required so that
    ///   `nsurlsessiond` can read staged files from outside the app, and so transfers survive
    ///   the app being terminated.

    public convenience init(sharedContainerIdentifier: String?) {
        self.init(
            sharedContainerIdentifier: sharedContainerIdentifier,
            makeSession: { WireDriveDirectUploadSession(identifier: $0, sharedContainerIdentifier: $1) }
        )
    }

    /// Exposed at module level so tests can inject a fake session without a real `URLSession`.

    init(
        sharedContainerIdentifier: String?,
        makeSession: @escaping @Sendable (String, String?) -> any WireDriveDirectUploadSessionProtocol
    ) {
        self.sharedContainerIdentifier = sharedContainerIdentifier
        self.makeSession = makeSession
    }

    // MARK: - Sessions

    /// The one and only session for `userID`, created on first use.

    func session(userID: UUID) -> any WireDriveDirectUploadSessionProtocol {
        session(identifier: Identifier.make(userID: userID))
    }

    private func session(identifier: String) -> any WireDriveDirectUploadSessionProtocol {
        lock.withLock { state in
            if let existing = state.sessions[identifier] {
                return existing
            }

            let session = makeSession(identifier, sharedContainerIdentifier)
            state.sessions[identifier] = session

            if let session = session as? WireDriveDirectUploadSession {
                session.setDidFinishEventsHandler { [weak self] identifier in
                    self?.didFinishEvents(identifier: identifier)
                }
            }

            return session
        }
    }

    // MARK: - Background launch events

    /// Claims the background session events iOS handed the app.
    @discardableResult
    public func handleEventsForBackgroundURLSession(
        identifier: String,
        completionHandler: @escaping @Sendable () -> Void
    ) -> Bool {
        guard Identifier.isDriveUploadSession(identifier) else {
            return false
        }

        WireLogger.wireDrive.info("claiming background upload session events")

        lock.withLock { $0.completionHandlers[identifier] = completionHandler }

        // Instantiating the session is what causes the queued delegate callbacks to be delivered.
        _ = session(identifier: identifier)

        return true
    }

    /// Calls and clears the stored completion handler for `identifier`.
    func didFinishEvents(identifier: String) {
        let handler = lock.withLock { $0.completionHandlers.removeValue(forKey: identifier) }

        guard let handler else { return }

        WireLogger.wireDrive.info("background upload session finished delivering events")

        // iOS requires this on the main queue.
        Task { @MainActor in
            handler()
        }
    }

    // MARK: - Attaching

    /// Routes the session's events to `sink`, draining anything buffered since launch.

    func attach(userID: UUID, sink: any WireDriveDirectUploadEventSink) async {
        await session(userID: userID).setEventSink(sink)
    }

    func detach(userID: UUID) async {
        let identifier = Identifier.make(userID: userID)
        let session = lock.withLock { $0.sessions[identifier] }
        await session?.removeEventSink()
    }

    /// Cancels every transfer for a user and forgets their session. For logout or account deletion.

    public func tearDown(userID: UUID) async {
        let identifier = Identifier.make(userID: userID)
        let session = lock.withLock { state in
            state.completionHandlers.removeValue(forKey: identifier)
            return state.sessions.removeValue(forKey: identifier)
        }

        guard let session else { return }

        await session.cancelAllTasks()
        await session.invalidate()
    }
}
