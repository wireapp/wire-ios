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

/// Tracks prolonged CoreCrypto MLS message buffering so the client can initiate stale epoch recovery.
///
/// If a commit is missed, CoreCrypto keeps buffering subsequent messages targeting the future epoch. The
/// `WrongEpoch` based recovery only kicks in once the epoch gap is large enough, which rarely happens in
/// conversations where the epoch seldom changes (e.g. 1:1 conversations).
///
/// Buffered event timestamps are tracked per conversation and subconversation. Recovery is requested when
/// their timestamp span exceeds `recoveryThreshold`, allowing short-lived out-of-order delivery to resolve
/// without intervention. Once recovery is requested, tracking for that conversation restarts so that recovery
/// is requested at most once per buffered time window.
///
/// Tracking is persisted in the `Journal`, so it survives process recreation and is shared between the
/// notification service extension (which creates new decryptors for each payload) and the main app.
/// Timestamps are server event timestamps, so they are comparable across processes.
///
/// Updates are a read-modify-write of the journal value and are not synchronized. This is acceptable since
/// events are decrypted sequentially and a lost update only delays recovery or causes a redundant one.

struct BufferedMLSMessageRecoveryTracker {

    static let defaultRecoveryThreshold: TimeInterval = 60

    private struct Entry: Codable {
        let groupID: Data
        let subconversation: String?
        var range: TimestampRange

        func matches(groupID: MLSGroupID, subconversation: String?) -> Bool {
            self.groupID == groupID.data && self.subconversation == subconversation
        }
    }

    private struct TimestampRange: Codable {
        let earliest: Date
        let latest: Date

        var span: TimeInterval {
            latest.timeIntervalSince(earliest)
        }

        func including(_ timestamp: Date) -> TimestampRange {
            TimestampRange(
                earliest: min(earliest, timestamp),
                latest: max(latest, timestamp)
            )
        }
    }

    private let journal: Journal
    private let recoveryThreshold: TimeInterval

    init(
        journal: Journal,
        recoveryThreshold: TimeInterval = BufferedMLSMessageRecoveryTracker.defaultRecoveryThreshold
    ) {
        self.journal = journal
        self.recoveryThreshold = recoveryThreshold
    }

    /// Records a buffered message.
    ///
    /// - Parameters:
    ///   - groupID: the MLS group id of the (parent) conversation.
    ///   - subconversation: the subconversation the message belongs to, if any.
    ///   - timestamp: the timestamp of the buffered event.
    ///
    /// - Returns: `true` if the buffered messages span more than the recovery threshold and recovery should be
    ///   initiated. In that case, tracking for the conversation restarts.

    func observeBufferedMessage(
        groupID: MLSGroupID,
        subconversation: String?,
        timestamp: Date
    ) -> Bool {
        var entries = loadEntries()
        let index = entries.firstIndex { $0.matches(groupID: groupID, subconversation: subconversation) }
        let updatedRange = index.map { entries[$0].range.including(timestamp) }
            ?? TimestampRange(earliest: timestamp, latest: timestamp)
        let shouldRecover = updatedRange.span > recoveryThreshold

        let leadingMessage = shouldRecover
            ? "buffered MLS message recovery triggered"
            : "buffered MLS message recovery tracking updated"
        WireLogger.mls.debug(
            "\(leadingMessage) (subconversation: \(subconversation ?? "<nil>"), " +
                "bufferedTimeSpan: \(updatedRange.span)s, recoveryThreshold: \(recoveryThreshold)s)",
            attributes: [
                .mlsGroupID: groupID.safeForLoggingDescription,
                .public: true
            ]
        )

        switch (shouldRecover, index) {
        case let (true, index?):
            entries.remove(at: index)
        case (true, nil):
            break
        case let (false, index?):
            entries[index].range = updatedRange
        case (false, nil):
            entries.append(Entry(groupID: groupID.data, subconversation: subconversation, range: updatedRange))
        }

        storeEntries(entries)
        return shouldRecover
    }

    /// Stops tracking buffered messages for the given conversation.
    ///
    /// Should be called when a message was successfully decrypted or when another recovery mechanism took over.

    func clear(groupID: MLSGroupID, subconversation: String?) {
        var entries = loadEntries()
        guard let index = entries.firstIndex(where: {
            $0.matches(groupID: groupID, subconversation: subconversation)
        }) else { return }

        entries.remove(at: index)
        storeEntries(entries)

        WireLogger.mls.debug(
            "buffered MLS message recovery tracking cleared",
            attributes: [
                .mlsGroupID: groupID.safeForLoggingDescription,
                .public: true
            ]
        )
    }

    // MARK: - Persistence

    private func loadEntries() -> [Entry] {
        guard let data = journal[.bufferedMLSMessageTimestampRanges] else {
            return []
        }

        do {
            return try JSONDecoder().decode([Entry].self, from: data)
        } catch {
            WireLogger.mls.warn("failed to decode buffered MLS message tracking, resetting: \(error)")
            return []
        }
    }

    private func storeEntries(_ entries: [Entry]) {
        guard !entries.isEmpty else {
            journal[.bufferedMLSMessageTimestampRanges] = nil
            return
        }

        do {
            journal[.bufferedMLSMessageTimestampRanges] = try JSONEncoder().encode(entries)
        } catch {
            WireLogger.mls.warn("failed to encode buffered MLS message tracking: \(error)")
        }
    }

}
