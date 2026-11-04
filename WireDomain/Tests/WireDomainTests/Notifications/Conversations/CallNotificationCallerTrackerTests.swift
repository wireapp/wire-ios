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
import WireNetwork
import WireTestingPackage
import XCTest

@testable import WireDomain

final class CallNotificationCallerTrackerTests: XCTestCase {

    private let accountID = UUID.mockID1
    private let conversationID = UUID.mockID2
    private let caller = UserID(id: .mockID3, domain: "a.example")
    private let responder = UserID(id: .mockID4, domain: "b.example")
    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: UUID.mockID5.uuidString)!
        defaults.removePersistentDomain(forName: UUID.mockID5.uuidString)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: UUID.mockID5.uuidString)
        defaults = nil
    }

    func testSameConferenceResponseKeepsFirstCallerAndEndConsumesItOnce() throws {
        let start = try callContent(type: "CONFSTART", timestamp: "1000")
        let response = try callContent(type: "CONFSTART", responded: true, timestamp: "1000")
        let repeatedStart = try callContent(type: "CONFSTART", timestamp: "1000")
        let startWithoutTimestamp = try callContent(type: "CONFSTART")
        let end = try callContent(type: "CONFEND")
        let startTime = Date(timeIntervalSince1970: 1000)
        let tracker = CallNotificationCallerTracker(userDefaults: defaults)

        XCTAssertNil(track(tracker, start, caller, at: startTime))
        XCTAssertNil(track(tracker, response, responder, at: startTime.addingTimeInterval(1)))
        XCTAssertNil(track(tracker, repeatedStart, responder, at: startTime.addingTimeInterval(2)))
        XCTAssertNil(track(tracker, startWithoutTimestamp, responder, at: startTime.addingTimeInterval(3)))

        let extensionDefaults = UserDefaults(suiteName: UUID.mockID5.uuidString)!
        let extensionTracker = CallNotificationCallerTracker(userDefaults: extensionDefaults)
        XCTAssertEqual(
            track(extensionTracker, end, responder, at: startTime.addingTimeInterval(4)),
            caller
        )
        XCTAssertNil(track(extensionTracker, end, responder, at: startTime.addingTimeInterval(5)))
    }

    func testNewConferenceReplacesCallerAndKeysAreScoped() throws {
        let firstStart = try callContent(type: "CONFSTART", timestamp: "1000")
        let secondStart = try callContent(type: "CONFSTART", timestamp: "2000")
        let end = try callContent(type: "CONFEND")
        let tracker = CallNotificationCallerTracker(userDefaults: defaults)

        _ = track(tracker, firstStart, caller)
        _ = track(tracker, secondStart, responder)

        XCTAssertNil(track(tracker, end, responder, accountID: UUID.mockID6))
        XCTAssertNil(track(tracker, end, responder, conversationID: UUID.mockID7))
        XCTAssertEqual(track(tracker, end, caller), responder)
    }

    func testExpiredCallerFallsBackToNoCachedIdentity() throws {
        let start = try callContent(type: "CONFSTART", timestamp: "1000")
        let end = try callContent(type: "CONFEND")
        let tracker = CallNotificationCallerTracker(userDefaults: defaults)
        let startTime = Date(timeIntervalSince1970: 1000)

        _ = track(tracker, start, caller, at: startTime)

        XCTAssertNil(track(tracker, end, responder, at: startTime.addingTimeInterval(24 * 60 * 60 + 1)))
    }

    private func track(
        _ tracker: CallNotificationCallerTracker,
        _ content: CallContent,
        _ sender: UserID,
        accountID: UUID? = nil,
        conversationID: UUID? = nil,
        at time: Date = .now
    ) -> UserID? {
        tracker.track(
            callContent: content,
            conversationID: conversationID ?? self.conversationID,
            accountID: accountID ?? self.accountID,
            senderID: sender,
            now: time
        )
    }

    private func callContent(type: String, responded: Bool = false, timestamp: String? = nil) throws -> CallContent {
        let timestampJSON = timestamp.map { "\"\($0)\"" } ?? "null"
        let data = Data("""
        {
            "type": "\(type)",
            "src_clientid": "client",
            "resp": \(responded),
            "timestamp": \(timestampJSON)
        }
        """.utf8)
        return try JSONDecoder().decode(CallContent.self, from: data)
    }
}
