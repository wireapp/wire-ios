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

import Darwin
public import Foundation
public import UserNotifications
public import WireCallingDomain

protocol MeetingReminderNotificationCenter {
    func authorizationStatus() async -> UNAuthorizationStatus
    func pendingRequestIdentifiers() async -> [String]
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: MeetingReminderNotificationCenter {
    func authorizationStatus() async -> UNAuthorizationStatus {
        await notificationSettings().authorizationStatus
    }

    func pendingRequestIdentifiers() async -> [String] {
        await withCheckedContinuation { continuation in
            getPendingNotificationRequests { requests in
                continuation.resume(returning: requests.map(\.identifier))
            }
        }
    }
}

/// Schedules one reminder with a fixed UTC fire date. Event reconciliation is handled by callers.
public struct MeetingReminderScheduler {

    private static let pendingRequestLimit = 64
    private static let reservedRequestCount = 16

    private let notificationCenter: any MeetingReminderNotificationCenter
    private let defaults: UserDefaults

    public init(defaults: UserDefaults? = nil) {
        self.notificationCenter = UNUserNotificationCenter.current()
        self.defaults = defaults ?? Self.sharedDefaults
    }

    init(notificationCenter: any MeetingReminderNotificationCenter, defaults: UserDefaults? = nil) {
        self.notificationCenter = notificationCenter
        self.defaults = defaults ?? UserDefaults(suiteName: "wire.meeting-reminder.test.\(UUID().uuidString)")!
    }

    /// Sends short-notice reminders immediately, once per occurrence, while the meeting is still upcoming.
    @discardableResult
    public func schedule(
        _ reminder: MeetingReminder,
        content: UNNotificationContent,
        now: Date = .now
    ) async throws -> Bool {
        let requestedAt = Date.now.timeIntervalSince1970
        return try await withMutationLock {
            guard shouldApplyMeetingMutation(requestedAt, reminder: reminder) else { return false }
            defer { recordMeetingMutation(requestedAt, reminder: reminder) }
            let pending = await notificationCenter.pendingRequestIdentifiers()
            let retained = Self.retainedIdentifiers(
                desired: [reminder],
                pending: pending,
                replacing: reminder.identifier
            )
            guard retained.contains(reminder.identifier) else { return false }
            let overflow = pending.filter {
                $0.hasPrefix(MeetingReminder.identifierNamespace) && !retained.contains($0)
            }
            if !overflow.isEmpty {
                notificationCenter.removePendingNotificationRequests(withIdentifiers: overflow)
                removeScheduledMarkers(for: overflow)
            }
            return try await scheduleUnlocked(reminder, content: content, now: now)
        }
    }

    @discardableResult
    private func scheduleUnlocked(
        _ reminder: MeetingReminder,
        content: UNNotificationContent,
        now: Date
    ) async throws -> Bool {
        guard reminder.occurrenceStart > now else { return false }

        switch await notificationCenter.authorizationStatus() {
        case .authorized, .provisional:
            break
        default:
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminder.identifier])
            return false
        }

        let isImmediate = reminder.fireDate <= now
        let scheduledKey = Self.scheduledKey(for: reminder)
        if isImmediate, defaults.bool(forKey: scheduledKey) {
            return false
        }

        let trigger: UNNotificationTrigger
        if isImmediate {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        } else {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            var fireComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: reminder.fireDate
            )
            fireComponents.calendar = calendar
            fireComponents.timeZone = calendar.timeZone
            trigger = UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: reminder.identifier,
            content: content,
            trigger: trigger
        )
        do {
            try await notificationCenter.add(request)
        } catch {
            // An earlier request with this identifier may still have outdated content.
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminder.identifier])
            throw error
        }
        // A calendar request may already have fired when a later refresh enters the short-notice window.
        defaults.set(true, forKey: scheduledKey)
        return true
    }

    public func cancel(_ reminder: MeetingReminder) async {
        await withMutationLock {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminder.identifier])
            defaults.removeObject(forKey: Self.scheduledKey(for: reminder))
            recordMeetingMutation(Date.now.timeIntervalSince1970, reminder: reminder)
        }
    }

    /// Replaces this account's pending reminders for one meeting with the supplied occurrences.
    /// Obsolete requests are removed before adding replacements so a changed start cannot fire twice.
    public func reconcile(
        accountID: UUID,
        meetingID: QualifiedID,
        occurrenceStarts: [Date],
        now: Date = .now,
        contentForOccurrence: (Date) -> UNNotificationContent
    ) async throws {
        let requestedAt = Date.now.timeIntervalSince1970
        try await withMutationLock {
            guard shouldApplyMeetingMutation(requestedAt, accountID: accountID, meetingID: meetingID) else {
                return
            }
            defer { recordMeetingMutation(requestedAt, accountID: accountID, meetingID: meetingID) }
            try await reconcileUnlocked(
                accountID: accountID,
                meetingID: meetingID,
                occurrenceStarts: occurrenceStarts,
                now: now,
                contentForOccurrence: contentForOccurrence
            )
        }
    }

    private func reconcileUnlocked(
        accountID: UUID,
        meetingID: QualifiedID,
        occurrenceStarts: [Date],
        now: Date,
        contentForOccurrence: (Date) -> UNNotificationContent
    ) async throws {
        let reminders = Set(occurrenceStarts).map {
            MeetingReminder(accountID: accountID, meetingID: meetingID, occurrenceStart: $0)
        }.filter { $0.occurrenceStart > now }
        let prefix = MeetingReminder.identifierPrefix(accountID: accountID, meetingID: meetingID)
        let pending = await notificationCenter.pendingRequestIdentifiers()
        let retained = Self.retainedIdentifiers(desired: reminders, pending: pending, replacing: prefix)
        let obsoleteIdentifiers = pending.filter {
            $0.hasPrefix(MeetingReminder.identifierNamespace) && !retained.contains($0)
        }

        if !obsoleteIdentifiers.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: obsoleteIdentifiers)
            removeScheduledMarkers(for: obsoleteIdentifiers)
        }

        var firstError: (any Error)?
        for reminder in reminders.filter({ retained.contains($0.identifier) })
            .sorted(by: { $0.occurrenceStart < $1.occurrenceStart }) {
            do {
                try await scheduleUnlocked(
                    reminder,
                    content: contentForOccurrence(reminder.occurrenceStart),
                    now: now
                )
            } catch {
                if firstError == nil { firstError = error }
            }
        }
        if let firstError { throw firstError }
    }

    /// Replaces this account's reminders after a successful authoritative meeting-list refresh.
    public func reconcileAll(
        accountID: UUID,
        meetings: [Meeting],
        occurrenceLimit: Int,
        now: Date = .now,
        contentForOccurrence: (Meeting, Date) -> UNNotificationContent
    ) async throws {
        let requestedAt = Date.now.timeIntervalSince1970
        try await withMutationLock {
            guard requestedAt >= defaults.double(forKey: Self.anyMutationKey(accountID: accountID)) else {
                return
            }
            defer { recordAccountMutation(requestedAt, accountID: accountID) }
            try await reconcileAllUnlocked(
                accountID: accountID,
                meetings: meetings,
                occurrenceLimit: occurrenceLimit,
                now: now,
                contentForOccurrence: contentForOccurrence
            )
        }
    }

    private func reconcileAllUnlocked(
        accountID: UUID,
        meetings: [Meeting],
        occurrenceLimit: Int,
        now: Date,
        contentForOccurrence: (Meeting, Date) -> UNNotificationContent
    ) async throws {
        let uniqueMeetings = Dictionary(meetings.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
            .values
        let calculator = MeetingReminderOccurrenceCalculator()
        let desired = uniqueMeetings.flatMap { meeting in
            calculator.starts(for: meeting, after: now, limit: occurrenceLimit).map { start in
                ScheduledMeetingReminder(
                    meeting: meeting,
                    reminder: MeetingReminder(accountID: accountID, meetingID: meeting.id, occurrenceStart: start)
                )
            }
        }
        let accountPrefix = MeetingReminder.accountIdentifierPrefix(accountID: accountID)
        let pending = await notificationCenter.pendingRequestIdentifiers()
        let retained = Self.retainedIdentifiers(
            desired: desired.map(\.reminder),
            pending: pending,
            replacing: accountPrefix
        )
        let obsoleteIdentifiers = pending.filter {
            $0.hasPrefix(MeetingReminder.identifierNamespace) && !retained.contains($0)
        }

        if !obsoleteIdentifiers.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: obsoleteIdentifiers)
            removeScheduledMarkers(for: obsoleteIdentifiers)
        }

        var firstError: (any Error)?
        for entry in desired.filter({ retained.contains($0.reminder.identifier) })
            .sorted(by: { $0.reminder.fireDate < $1.reminder.fireDate }) {
            do {
                try await scheduleUnlocked(
                    entry.reminder,
                    content: contentForOccurrence(entry.meeting, entry.reminder.occurrenceStart),
                    now: now
                )
            } catch {
                if firstError == nil { firstError = error }
            }
        }
        if let firstError { throw firstError }
    }

    /// Requests cancellation of every pending occurrence for one qualified meeting and account.
    public func cancelAll(accountID: UUID, meetingID: QualifiedID) async {
        await withMutationLock {
            let prefix = MeetingReminder.identifierPrefix(accountID: accountID, meetingID: meetingID)
            let identifiers = await notificationCenter.pendingRequestIdentifiers()
                .filter { $0.hasPrefix(prefix) }
            if !identifiers.isEmpty {
                notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
            }
            removeScheduledMarkers(matching: prefix)
            recordMeetingMutation(Date.now.timeIntervalSince1970, accountID: accountID, meetingID: meetingID)
        }
    }

    /// Requests cancellation of every pending meeting reminder for one account.
    public func cancelAll(accountID: UUID) async {
        await withMutationLock {
            let prefix = MeetingReminder.accountIdentifierPrefix(accountID: accountID)
            let identifiers = await notificationCenter.pendingRequestIdentifiers()
                .filter { $0.hasPrefix(prefix) }
            if !identifiers.isEmpty {
                notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
            }
            removeScheduledMarkers(matching: prefix)
            recordAccountMutation(Date.now.timeIntervalSince1970, accountID: accountID)
        }
    }

    /// Removes reminders for accounts that are no longer signed in while preserving other notifications.
    public func cancelAll(exceptAccountIDs accountIDs: Set<UUID>) async {
        await withMutationLock {
            let retainedPrefixes = accountIDs.map { MeetingReminder.accountIdentifierPrefix(accountID: $0) }
            let identifiers = await notificationCenter.pendingRequestIdentifiers().filter { identifier in
                identifier.hasPrefix(MeetingReminder.identifierNamespace)
                    && !retainedPrefixes.contains(where: identifier.hasPrefix)
            }
            if !identifiers.isEmpty {
                notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
            }
            for identifier in identifiers {
                let accountPart = identifier.dropFirst(MeetingReminder.identifierNamespace.count).split(separator: "|")
                    .first
                if let accountPart, let accountID = UUID(uuidString: String(accountPart)) {
                    recordAccountMutation(Date.now.timeIntervalSince1970, accountID: accountID)
                }
            }
            let markerPrefix = Self.scheduledKeyPrefix
            for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(markerPrefix) {
                let identifier = String(key.dropFirst(markerPrefix.count))
                if !retainedPrefixes.contains(where: identifier.hasPrefix) {
                    defaults.removeObject(forKey: key)
                }
            }
        }
    }

    private static let scheduledKeyPrefix = "wire.meeting-reminder.scheduled|"
    private static let mutationKeyPrefix = "wire.meeting-reminder.mutation|"

    private static func anyMutationKey(accountID: UUID) -> String {
        mutationKeyPrefix + "any|" + accountID.uuidString
    }

    private static func accountMutationKey(accountID: UUID) -> String {
        mutationKeyPrefix + "account|" + accountID.uuidString
    }

    private static func meetingMutationKey(accountID: UUID, meetingID: QualifiedID) -> String {
        mutationKeyPrefix + MeetingReminder.identifierPrefix(accountID: accountID, meetingID: meetingID)
    }

    private func shouldApplyMeetingMutation(_ time: TimeInterval, reminder: MeetingReminder) -> Bool {
        shouldApplyMeetingMutation(time, accountID: reminder.accountID, meetingID: reminder.meetingID)
    }

    private func shouldApplyMeetingMutation(_ time: TimeInterval, accountID: UUID, meetingID: QualifiedID) -> Bool {
        time >= defaults.double(forKey: Self.accountMutationKey(accountID: accountID))
            && time >= defaults.double(forKey: Self.meetingMutationKey(accountID: accountID, meetingID: meetingID))
    }

    private func recordMeetingMutation(_ time: TimeInterval, reminder: MeetingReminder) {
        recordMeetingMutation(time, accountID: reminder.accountID, meetingID: reminder.meetingID)
    }

    private func recordMeetingMutation(_ time: TimeInterval, accountID: UUID, meetingID: QualifiedID) {
        let meetingKey = Self.meetingMutationKey(accountID: accountID, meetingID: meetingID)
        let anyKey = Self.anyMutationKey(accountID: accountID)
        defaults.set(max(time, defaults.double(forKey: meetingKey)), forKey: meetingKey)
        defaults.set(max(time, defaults.double(forKey: anyKey)), forKey: anyKey)
    }

    private func recordAccountMutation(_ time: TimeInterval, accountID: UUID) {
        let accountKey = Self.accountMutationKey(accountID: accountID)
        let anyKey = Self.anyMutationKey(accountID: accountID)
        defaults.set(max(time, defaults.double(forKey: accountKey)), forKey: accountKey)
        defaults.set(max(time, defaults.double(forKey: anyKey)), forKey: anyKey)
    }

    private static var sharedDefaults: UserDefaults {
        guard let groupID = Bundle.main.object(forInfoDictionaryKey: "WireGroupId") as? String else {
            return .standard
        }
        return UserDefaults(suiteName: "group.\(groupID)") ?? .standard
    }

    private static func scheduledKey(for reminder: MeetingReminder) -> String {
        scheduledKeyPrefix + reminder.identifier
    }

    private func removeScheduledMarkers(matching identifierPrefix: String) {
        let prefix = Self.scheduledKeyPrefix + identifierPrefix
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            defaults.removeObject(forKey: key)
        }
    }

    private func removeScheduledMarkers(for identifiers: [String]) {
        for identifier in identifiers {
            defaults.removeObject(forKey: Self.scheduledKeyPrefix + identifier)
        }
    }

    private static func retainedIdentifiers(
        desired: [MeetingReminder],
        pending: [String],
        replacing prefix: String
    ) -> Set<String> {
        let preserved = pending.filter { !$0.hasPrefix(prefix) }
        let unrelatedCount = preserved.filter { !$0.hasPrefix(MeetingReminder.identifierNamespace) }.count
        let budget = max(0, pendingRequestLimit - max(reservedRequestCount, unrelatedCount))
        let candidates = Set(desired.map(\.identifier) + preserved.filter {
            $0.hasPrefix(MeetingReminder.identifierNamespace)
        })
        return Set(candidates.sorted { first, second in
            let firstStart = Int64(first.split(separator: "|").last ?? "") ?? .max
            let secondStart = Int64(second.split(separator: "|").last ?? "") ?? .max
            return firstStart == secondStart ? first < second : firstStart < secondStart
        }.prefix(budget))
    }

    private func withMutationLock<Result>(_ operation: () async throws -> Result) async rethrows -> Result {
        let descriptor = await Self.acquireMutationLock()
        _ = defaults.synchronize()
        defer {
            _ = defaults.synchronize()
            if descriptor >= 0 {
                flock(descriptor, LOCK_UN)
                close(descriptor)
            }
        }
        return try await operation()
    }

    private static func acquireMutationLock() async -> Int32 {
        let fileManager = FileManager.default
        let directory: URL = if let groupID = Bundle.main.object(forInfoDictionaryKey: "WireGroupId") as? String,
                                let sharedDirectory = fileManager
                                .containerURL(forSecurityApplicationGroupIdentifier: "group.\(groupID)") {
            sharedDirectory
        } else {
            fileManager.temporaryDirectory
        }
        let path = directory.appendingPathComponent("wire-meeting-reminders.lock").path
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let descriptor = path.withCString { open($0, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR) }
                if descriptor >= 0, flock(descriptor, LOCK_EX) != 0 {
                    close(descriptor)
                    continuation.resume(returning: -1)
                    return
                }
                continuation.resume(returning: descriptor)
            }
        }
    }

}

private struct ScheduledMeetingReminder {
    let meeting: Meeting
    let reminder: MeetingReminder
}
