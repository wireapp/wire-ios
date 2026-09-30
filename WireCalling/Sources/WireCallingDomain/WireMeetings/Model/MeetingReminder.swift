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
public import WireFoundation

/// Identifies one local reminder for one occurrence of a meeting on one account.
public struct MeetingReminder: Hashable, Sendable {

    public static let leadTime: TimeInterval = 10 * 60

    public let accountID: UUID
    public let meetingID: QualifiedID
    public let occurrenceStart: Date

    public init(accountID: UUID, meetingID: QualifiedID, occurrenceStart: Date) {
        self.accountID = accountID
        self.meetingID = meetingID
        self.occurrenceStart = occurrenceStart
    }

    /// Namespaced so reconciliation can select only requests belonging to this feature.
    public var identifier: String {
        let startMilliseconds = Int64((occurrenceStart.timeIntervalSince1970 * 1000).rounded())
        return [
            "wire.meeting-reminder.v1",
            accountID.uuidString,
            meetingID.id.uuidString,
            meetingID.domain,
            String(startMilliseconds)
        ].joined(separator: "|")
    }

    public var fireDate: Date {
        occurrenceStart.addingTimeInterval(-Self.leadTime)
    }

}
