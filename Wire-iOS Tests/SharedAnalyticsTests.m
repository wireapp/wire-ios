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


@import Foundation;
@import WireExtensionComponents;
@import XCTest;
@import OCMock;



@interface SharedAnalytics (Test)
@property (nonatomic, readonly) NSUserDefaults *defaults;
@end



@interface SharedAnalyticsTests : XCTestCase

@end

@implementation SharedAnalyticsTests

- (void)setUp
{
    [super setUp];
    
    id sharedAnalyticsMock = OCMClassMock([SharedAnalytics class]);
    OCMStub([sharedAnalyticsMock defaults]).andReturn([NSUserDefaults standardUserDefaults]);
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testThatItCanStoreAnalyticsEvents
{
    // GIVEN
    SharedAnalytics *analytics = [SharedAnalytics sharedInstance];
    [analytics storeEvent:@"testEvent1"
                  context:@"UnitTests"
               attributes:nil];
    [analytics storeEvent:@"testEvent2"
                  context:@"UnitTests"
               attributes:@{@"attribute":@"value"}];
    
    // WHEN
    NSArray *fetchedEvents = [analytics allEvents];
    
    // THEN
    XCTAssertNotNil(fetchedEvents);
    XCTAssertEqual(fetchedEvents.count, 2lu, @"2 events should be stored");
    
    SharedAnalyticsEvent *event0 = fetchedEvents[0];
    XCTAssertNotNil(event0);
    XCTAssertEqualObjects(event0.eventName, @"testEvent1");
    XCTAssertNil(event0.attributes);
    
    SharedAnalyticsEvent *event1 = fetchedEvents[1];
    XCTAssertNotNil(event1);
    XCTAssertEqualObjects(event1.eventName, @"testEvent2");
    
    NSDictionary *attributes = event1.attributes;
    XCTAssertNotNil(attributes);
}

- (void)testThatItCanRemoveAnalyticsEvents
{
    // GIVEN
    SharedAnalytics *analytics = [SharedAnalytics sharedInstance];
    [analytics storeEvent:@"testEvent1"
                  context:@"UnitTests"
               attributes:nil];
    [analytics storeEvent:@"testEvent2"
                  context:@"UnitTests"
               attributes:@{@"attribute":@"value"}];

    // WHEN
    [analytics removeAllEvents];
    
    // THEN
    NSArray *fetchedEvents = [analytics allEvents];
    XCTAssertNotNil(fetchedEvents);
    XCTAssertEqual(fetchedEvents.count, 0lu, @"No events should be stored");
}

@end
