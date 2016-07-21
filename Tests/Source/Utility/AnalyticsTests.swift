// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import XCTest
import ZMTesting
@testable import zmessaging

struct EventWithAttributes: Equatable {
    let event: String
    let attributes: [String: NSObject]
}

func ==(lhs: EventWithAttributes, rhs: EventWithAttributes) -> Bool {
    return lhs.event == rhs.event && lhs.attributes == rhs.attributes
}

final class MockAnalytics: NSObject, AnalyticsType {
    
    @objc func tagEvent(event: String) {
        taggedEvents.append(event)
    }
    
    @objc func tagEvent(event: String, attributes: [String : NSObject]) {
        taggedEventsWithAttributes.append(EventWithAttributes(event: event, attributes: attributes))
    }
    
    @objc func upload() {
        uploadCallCount += 1
    }

    var taggedEvents = [String]()
    var taggedEventsWithAttributes = [EventWithAttributes]()
    var uploadCallCount = 0
}


class AnalyticsTests: XCTestCase {
    
    var analytics: MockAnalytics!
    
    override func setUp() {
        super.setUp()
        analytics = MockAnalytics()
    }
    
    func testThatItSetsAnalyticsOnManagedObjectContext() {
        // given
        let context = NSManagedObjectContext.createSyncContext()
        context.markAsSyncContext()
        
        // when
        context.analytics = analytics
        
        // then
        XCTAssertNotNil(context.analytics)
        XCTAssertEqual(context.analytics as? MockAnalytics, analytics)
        context.analytics = nil
        XCTAssertNil(context.analytics)
    }

    func testVOIPTimeDifferenceTracking() {
        // given
        let notificationID = NSUUID.createUUID()
        let serverTime = NSDate(timeIntervalSinceNow: -5)
        let referenceDate = NSDate(timeIntervalSinceNow: 0.5)

        // when
        let tracker = APNSPerformanceTracker()

        tracker.trackNotification(notificationID, state: .OperationLoop(serverTimestamp: serverTime, notificationsEnabled: true, background: true), analytics: analytics)
        tracker.trackNotification(notificationID, state: .PingBackStatus, analytics: analytics, referenceDate: referenceDate)

        // then
        XCTAssertTrue(analytics.taggedEvents.isEmpty)
        XCTAssertEqual(analytics.taggedEventsWithAttributes.count, 2) // UserSession & OperationLoop
        let firstEventWithAttribute = analytics.taggedEventsWithAttributes.first
        let secondEventWithAttribute = analytics.taggedEventsWithAttributes.last

        let firstExpected = EventWithAttributes(event: "apns_performance", attributes: [
            "server_timestamp_difference": "4000-5000",
            "notification_identifier": notificationID.transportString(),
            "state_description": "OperationLoop",
            "state_index": 0,
            "allowed_notifications": true,
            "background": true
        ])

        XCTAssertEqual(firstEventWithAttribute, firstExpected)

        let secondExpected = EventWithAttributes(event: "apns_performance", attributes: [
            "notification_identifier": notificationID.transportString(),
            "state_description": "PingBackStatus",
            "state_index": 1,
            "time_since_last": "200-500"
        ])
        
        XCTAssertEqual(secondEventWithAttribute, secondExpected)
    }
}
