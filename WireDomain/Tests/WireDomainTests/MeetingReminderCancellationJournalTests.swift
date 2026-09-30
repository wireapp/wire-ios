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
import Testing

@testable import WireDomain

@Suite("Meeting reminder cancellation journal")
struct MeetingReminderCancellationJournalTests {

    @Test("persists pending cancellation for separate accounts")
    func persistsMultipleAccounts() throws {
        let suiteName = "meeting-reminder-journal-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let firstAccountID = UUID()
        let secondAccountID = UUID()
        let journal = MeetingReminderCancellationJournal(defaults: defaults)

        let firstToken = journal.record(accountID: firstAccountID)
        let secondToken = journal.record(accountID: secondAccountID)

        #expect(MeetingReminderCancellationJournal(defaults: defaults).pending() == [
            firstAccountID: firstToken,
            secondAccountID: secondToken
        ])

        journal.clear(accountID: firstAccountID, token: firstToken)
        #expect(journal.pending() == [secondAccountID: secondToken])
    }

    @Test("an earlier cancellation cannot clear a newer request for the same account")
    func preservesNewerCancellation() throws {
        let suiteName = "meeting-reminder-journal-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let accountID = UUID()
        let journal = MeetingReminderCancellationJournal(defaults: defaults)

        let oldToken = journal.record(accountID: accountID)
        let newToken = journal.record(accountID: accountID)
        journal.clear(accountID: accountID, token: oldToken)

        #expect(journal.pending() == [accountID: newToken])
    }

}
