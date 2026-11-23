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
import WireCoreCrypto
import WireDataModel
import WireLogging

protocol ProteusSessionRepairScheduling {

    /// Schedules an automatic repair of the Proteus session with the given remote client, if `error` indicates
    /// that the session is broken and no repair was scheduled for that client recently.
    func scheduleRepairIfNeeded(
        for error: ProteusService.DecryptionError,
        senderUserID: UUID,
        senderClientID: String
    ) async

}

/// Schedules the repair of Proteus sessions that are broken, i.e. every message from a remote client fails to
/// decrypt because the local session lost the keys that client encrypts for.
///
/// The repair itself is performed by `ResetSessionRequestStrategy` in the main app: it rebuilds the session from the
/// client's prekey and sends a session reset message to that client only. This type only sets
/// `UserClient.needsToNotifyOtherUserAboutSessionReset`, which doesn't touch CoreCrypto, so it is safe to call while
/// decrypting inside a CoreCrypto transaction.
///
/// It is only used in the main app: a running app doesn't see the flag saved by the notification service extension.
///
/// To avoid two clients resetting each other in a loop, a repair is scheduled at most once per client within
/// `minimumInterval`. Attempts are persisted in the `Journal`. Updates are a read-modify-write of the journal value
/// and are not synchronized; events are decrypted sequentially, and a lost update only causes one redundant repair.

struct ProteusSessionRepairScheduler: ProteusSessionRepairScheduling {

    static let defaultMinimumInterval: TimeInterval = 24 * 60 * 60

    private let journal: Journal
    private let context: NSManagedObjectContext
    private let minimumInterval: TimeInterval
    private let now: () -> Date

    init(
        journal: Journal,
        context: NSManagedObjectContext,
        minimumInterval: TimeInterval = ProteusSessionRepairScheduler.defaultMinimumInterval,
        now: @escaping () -> Date = Date.init
    ) {
        self.journal = journal
        self.context = context
        self.minimumInterval = minimumInterval
        self.now = now
    }

    func scheduleRepairIfNeeded(
        for error: ProteusService.DecryptionError,
        senderUserID: UUID,
        senderClientID: String
    ) async {
        guard Self.indicatesBrokenSession(error) else {
            return
        }

        let attemptKey = "\(senderUserID.uuidString)/\(senderClientID)"
        let currentDate = now()
        var attempts = loadAttempts()

        if let lastAttempt = attempts[attemptKey], isRecent(lastAttempt, at: currentDate) {
            WireLogger.proteus.info(
                "session with client \(senderClientID.redactedAndTruncated()) looks broken, repair already scheduled",
                attributes: .safePublic
            )
            return
        }

        let didSchedule = await context.perform { [context] in
            guard
                let client = UserClient.fetchExistingUserClient(with: senderClientID, in: context),
                client.user?.remoteIdentifier == senderUserID
            else {
                return false
            }
            client.needsToNotifyOtherUserAboutSessionReset = true
            return true
        }

        guard didSchedule else {
            WireLogger.proteus.warn(
                "can't schedule repair of broken session: unknown client \(senderClientID.redactedAndTruncated())",
                attributes: .safePublic
            )
            return
        }

        WireLogger.proteus.info(
            "scheduled repair of broken session with client \(senderClientID.redactedAndTruncated())",
            attributes: .safePublic
        )

        attempts[attemptKey] = currentDate
        // Drop attempts that no longer limit anything, so the journal value doesn't grow forever.
        attempts = attempts.filter { isRecent($0.value, at: currentDate) }
        storeAttempts(attempts)
    }

    /// Whether `attempt` still limits repairs at `date`. Attempts in the future (e.g. after the clock was changed)
    /// don't, so they can't block repairs indefinitely.
    private func isRecent(_ attempt: Date, at date: Date) -> Bool {
        let elapsed = date.timeIntervalSince(attempt)
        return elapsed >= 0 && elapsed < minimumInterval
    }

    /// Whether decryption failed because the existing session doesn't match the sender's anymore.
    ///
    /// - 406 (`InvalidSignature`): the message's MAC doesn't verify, e.g. the local session lost the ratchet key the
    ///   sender encrypts for.
    /// - 202 (`InvalidMessage`): the message uses a session state the local session doesn't know.
    ///
    /// Only failures with an existing session count. Duplicate or outdated messages and a changed remote identity
    /// are not damage that a session reset repairs automatically.
    static func indicatesBrokenSession(_ error: ProteusService.DecryptionError) -> Bool {
        guard
            case let .failedToDecryptData(proteusError) = error,
            case let .Other(code) = proteusError
        else {
            return false
        }
        return code == 406 || code == 202
    }

    // MARK: - Persistence

    private func loadAttempts() -> [String: Date] {
        guard let data = journal[.proteusSessionRepairAttempts] else {
            return [:]
        }
        return (try? JSONDecoder().decode([String: Date].self, from: data)) ?? [:]
    }

    private func storeAttempts(_ attempts: [String: Date]) {
        journal[.proteusSessionRepairAttempts] = try? JSONEncoder().encode(attempts)
    }

}
