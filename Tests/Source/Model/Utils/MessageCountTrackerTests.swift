//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
@testable import WireDataModel


private class DateCreator {
    var nextDate: Date!

    func create() -> Date {
        return nextDate
    }
}


private class MockCountFetcher: CountFetcherType {

    var callCount = 0

    func fetchNumberOfLegacyMessages(_ completion: @escaping (MessageCount) -> Void) {
        callCount += 1
    }
}

final private class MockAnalytics: NSObject, AnalyticsType {

    var eventAttributes = [String : [String : NSObject]]()
    public func setPersistedAttributes(_ attributes: [String : NSObject]?, for event: String) {
        if let attributes = attributes {
            eventAttributes[event] = attributes
        } else {
            eventAttributes.removeValue(forKey: event)
        }
    }

    public func persistedAttributes(for event: String) -> [String : NSObject]? {
        let value = eventAttributes[event] ?? [:]
        return value
    }

    var taggedEvents = [String]()
    var taggedEventsWithAttributes = [(String, [String: NSObject])]()

    @objc func tagEvent(_ event: String) {
        taggedEvents.append(event)
    }

    @objc func tagEvent(_ event: String, attributes: [String : NSObject]) {
        taggedEventsWithAttributes.append((event, attributes))
    }

    @objc func upload() {}
}


fileprivate extension Int {

    func times(_ execute: () -> Void) {
        (0..<self).forEach { _ in execute() }
    }

}


class MessageCountTrackerTests: BaseZMMessageTests {

    fileprivate var mockFetcher: MockCountFetcher!

    override func setUp() {
        super.setUp()
        mockFetcher = MockCountFetcher()
    }

    override func tearDown() {
        mockFetcher = nil
        super.tearDown()
    }

    // MARK: - Execution Interval

    func testThatItTracksTheMessageCountInitially() {
        // Given
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let currentDate = Date()
        let dateCreator = DateCreator()
        dateCreator.nextDate = currentDate

        guard let sut = LegacyMessageTracker(
            managedObjectContext: syncMOC,
            userDefaults: defaults,
            createDate: dateCreator.create,
            countFetcher: mockFetcher
        ) else { return XCTFail("Unable to create SUT") }

        // When
        XCTAssertNil(sut.lastTrackDate)
        XCTAssertTrue(sut.shouldTrack())
        sut.trackLegacyMessageCount()

        // Then
        XCTAssertEqual(sut.lastTrackDate, currentDate)
        XCTAssertEqual(mockFetcher.callCount, 1)
        XCTAssertFalse(sut.shouldTrack())
    }

    func testThatItDoesNotTrackTheMessageCountWhenItTrackedInTheLast14Days() {
        // Given
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let currentDate = Date()
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: currentDate)

        let dateCreator = DateCreator()
        dateCreator.nextDate = currentDate

        guard let sut = LegacyMessageTracker(
            managedObjectContext: syncMOC,
            userDefaults: defaults,
            createDate: dateCreator.create,
            countFetcher: mockFetcher
            ) else { return XCTFail("Unable to create SUT") }

        // When
        sut.lastTrackDate = oneWeekAgo
        XCTAssertFalse(sut.shouldTrack())
        sut.trackLegacyMessageCount()

        // Then
        XCTAssertEqual(sut.lastTrackDate, oneWeekAgo)
        XCTAssertEqual(mockFetcher.callCount, 0)
    }

    func testThatItTracksTheMessageCountWhenItTrackedTheLastTimeBeforeMoreThan14Days() {
        // Given
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let currentDate = Date()
        let fifteenDaysAgo = Calendar.current.date(byAdding: .day, value: -15, to: currentDate)

        let dateCreator = DateCreator()
        dateCreator.nextDate = currentDate

        guard let sut = LegacyMessageTracker(
            managedObjectContext: syncMOC,
            userDefaults: defaults,
            createDate: dateCreator.create,
            countFetcher: mockFetcher
            ) else { return XCTFail("Unable to create SUT") }

        // When
        sut.lastTrackDate = fifteenDaysAgo
        XCTAssertTrue(sut.shouldTrack())
        sut.trackLegacyMessageCount()

        // Then
        XCTAssertEqual(sut.lastTrackDate, currentDate)
        XCTAssertEqual(mockFetcher.callCount, 1)
    }

    // MARK: - Tracking

    func testThatItTracksTheClusterizedCountsOfMessagesInTheDatabase() {
        // Given
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let mockAnalytics = MockAnalytics()

        syncMOC.performGroupedBlockAndWait {
            self.syncMOC.analytics = mockAnalytics
            101.times { _ = ZMClientMessage(nonce: UUID(), managedObjectContext: self.syncMOC) }
            4.times { _ = ZMImageMessage(nonce: UUID(), managedObjectContext: self.syncMOC) }
            3.times { _ = ZMAssetClientMessage(nonce: UUID(), managedObjectContext: self.syncMOC) }
            2.times { _ = ZMTextMessage(nonce: UUID(), managedObjectContext: self.syncMOC) }
        }

        // When
        guard let sut = LegacyMessageTracker(managedObjectContext: syncMOC, userDefaults: defaults, createDate: Date.init) else { return XCTFail("Unable to create SUT") }

        performIgnoringZMLogError {
            sut.trackLegacyMessageCount()
            XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }

        // Then
        guard let (event, attributes) = mockAnalytics.taggedEventsWithAttributes.first else { return XCTFail("No tracking data") }
        XCTAssertEqual(event, "message_count")
        XCTAssertEqual(attributes["client_messages"] as? String, "100-250")
        XCTAssertEqual(attributes["unencrypted_images"] as? String, "0-100")
        XCTAssertEqual(attributes["asset_messages"] as? String, "0-100")
        XCTAssertEqual(attributes["unencrypted_text"] as? String, "0-100")
    }

}
