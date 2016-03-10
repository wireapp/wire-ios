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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


@import ZMTransport;
@import ZMTesting;

#import "ZMEventIDRangeSet.h"


@interface ZMEventIDRangeSetTests : ZMTBaseTest

@end

@implementation ZMEventIDRangeSetTests

- (void)testThatWeCanAddAnEvent
{
    // given
    ZMEventID *event = [ZMEventID eventIDWithString:@"23.44"];
    
    // when
    ZMEventIDRangeSet *sut = [[ZMEventIDRangeSet alloc] initWithEvent:event];
    
    // then
    XCTAssertTrue([sut containsEvent:event]);
}

- (void)testThatContainsEventReturnsTheRightValue
{
    // given
    ZMEventID *event1 = [ZMEventID eventIDWithString:@"23.44"];
    ZMEventID *event2 = [ZMEventID eventIDWithString:@"23.48"];
    
    // when
    ZMEventIDRangeSet *sut = [[ZMEventIDRangeSet alloc] initWithEvent:event1];
    
    // then
    XCTAssertTrue([sut containsEvent:event1]);
    XCTAssertFalse([sut containsEvent:event2]);
}

- (void)testThatWeCanAddAnEventRange
{
    // given
    NSArray *eventStrings = @[@"2.2", @"2.3"];
    ZMEventIDRange *range = [[ZMEventIDRange alloc] init];
    [range addEvent:[ZMEventID eventIDWithString:eventStrings[0]]];
    [range addEvent:[ZMEventID eventIDWithString:eventStrings[1]]];

    // when
    ZMEventIDRangeSet *sut = [[ZMEventIDRangeSet alloc] initWithRanges:@[range]];
    
    // then
    for (NSString *s in eventStrings) {
        XCTAssertTrue([sut containsEvent:[ZMEventID eventIDWithString:s]], @"%@", s);
    }
    XCTAssertFalse([sut containsEvent:[ZMEventID eventIDWithString:@"1.1"]]);
    XCTAssertFalse([sut containsEvent:[ZMEventID eventIDWithString:@"5.5"]]);
}

- (void)testThatItReturnsGapWithNoWindow
{
    // given
    NSArray* events = @[
                        [ZMEventID eventIDWithString:@"1.5"],
                        [ZMEventID eventIDWithString:@"5.5"],
                        [ZMEventID eventIDWithString:@"10.5"],
                        [ZMEventID eventIDWithString:@"15.5"]
                        ];
    
    ZMEventIDRange *range1 = [[ZMEventIDRange alloc] init];
    [range1 addEvent:events[0]];
    [range1 addEvent:events[1]];
    
    ZMEventIDRange *range2 = [[ZMEventIDRange alloc] init];
    [range2 addEvent:events[2]];
    [range2 addEvent:events[3]];

    ZMEventIDRange *expectedGap = [[ZMEventIDRange alloc] init];
    [expectedGap addEvent:events[1]];
    [expectedGap addEvent:events[2]];
    
    ZMEventIDRangeSet *sut = [[ZMEventIDRangeSet alloc] initWithRanges:@[range1, range2]];
    
    // when
    ZMEventIDRange *gap = [sut firstGapWithinWindow:nil];
    
    // then
    XCTAssertNotNil(gap);
    XCTAssertEqualObjects(gap, expectedGap);
}

- (void)testThatItSerializesAndDeserializes
{
    // given
    NSArray* events = @[
                        [ZMEventID eventIDWithString:@"1.800122000a68f010"],
                        [ZMEventID eventIDWithString:@"5.800122000a68f00a"],
                        [ZMEventID eventIDWithString:@"8.5"],
                        [ZMEventID eventIDWithString:@"9.5"]
                        ];
    
    ZMEventIDRange *range1 = [[ZMEventIDRange alloc] init];
    [range1 addEvent:events[0]];
    [range1 addEvent:events[1]];
    
    ZMEventIDRange *range2 = [[ZMEventIDRange alloc] init];
    [range2 addEvent:events[2]];
    [range2 addEvent:events[3]];
    
    ZMEventIDRangeSet *sut = [[ZMEventIDRangeSet alloc] initWithRanges:@[range1, range2]];
    
    // when
    NSData *serialized = [sut serializeToData];
    ZMEventIDRangeSet *deserialized = [[ZMEventIDRangeSet alloc] initWithData:serialized];
    
    // then
    XCTAssertEqualObjects(sut, deserialized);
    
}

- (void)testThatItComparesEqual
{
    // given
    NSArray* events = @[
                        [ZMEventID eventIDWithString:@"1.800122000a68f010"],
                        [ZMEventID eventIDWithString:@"5.800122000a68f005"],
                        [ZMEventID eventIDWithString:@"10.5"],
                        [ZMEventID eventIDWithString:@"15.5"]
                        ];
    
    ZMEventIDRange *range1 = [[ZMEventIDRange alloc] init];
    [range1 addEvent:events[0]];
    [range1 addEvent:events[1]];
    
    ZMEventIDRange *range2 = [[ZMEventIDRange alloc] init];
    [range2 addEvent:events[2]];
    [range2 addEvent:events[3]];
    
    ZMEventIDRangeSet *set1 = [[ZMEventIDRangeSet alloc] initWithRanges:@[range1, range2]];
    ZMEventIDRangeSet *set2 = [[ZMEventIDRangeSet alloc] initWithRanges:@[range1, range2]];
    ZMEventIDRangeSet *set3 = [[ZMEventIDRangeSet alloc] init];

    // then
    XCTAssertEqualObjects(set1, set2);
    XCTAssertEqualObjects(set2, set1);
    XCTAssertNotEqualObjects(set1, set3);
    XCTAssertNotEqualObjects(set3, set2);
    XCTAssertNotEqualObjects(set1, nil);
    XCTAssertNotEqualObjects(set3, nil);
}

- (void)testThatItDoesNotCrashOnNil
{
    // when
    XCTAssertNotNil([[ZMEventIDRangeSet alloc] initWithData:nil]);
    XCTAssertNotNil([[ZMEventIDRangeSet alloc] initWithEvent:nil]);
    XCTAssertNotNil([[ZMEventIDRangeSet alloc] initWithRanges:nil]);

}

- (void)testThatItSetsMessageWindowThatIncludesEntireInterval
{
    // given
    NSArray* events = @[
                        [ZMEventID eventIDWithString:@"1.800122000a68f010"],
                        [ZMEventID eventIDWithString:@"5.800122000a68f005"],
                        [ZMEventID eventIDWithString:@"10.5"],
                        [ZMEventID eventIDWithString:@"15.5"]
                        ];
    
    ZMEventIDRange *range1 = [[ZMEventIDRange alloc] init];
    [range1 addEvent:events[0]];
    [range1 addEvent:events[1]];
    
    ZMEventIDRange *range2 = [[ZMEventIDRange alloc] init];
    [range2 addEvent:events[2]];
    [range2 addEvent:events[3]];
    
    ZMEventIDRange *window = [[ZMEventIDRange alloc] init];
    [window addEvent:events[0]];
    [window addEvent:events[3]];
    
    ZMEventIDRange *expectedGap = [[ZMEventIDRange alloc] init];
    [expectedGap addEvent:events[1]];
    [expectedGap addEvent:events[2]];
    
    // when
    ZMEventIDRangeSet *sut = [[ZMEventIDRangeSet alloc] initWithRanges:@[range1, range2]];
    
    // then
    XCTAssertEqualObjects([sut firstGapWithinWindow:window], expectedGap);
}

- (void)testThatItSetsMessageWindowThatExcludesEntireInterval
{
    // given
    NSArray* events = @[
                        [ZMEventID eventIDWithString:@"1.800122000a68f010"],
                        [ZMEventID eventIDWithString:@"5.800122000a68f005"],
                        [ZMEventID eventIDWithString:@"10.5"],
                        [ZMEventID eventIDWithString:@"15.5"]
                        ];
    
    ZMEventIDRange *range1 = [[ZMEventIDRange alloc] init];
    [range1 addEvent:events[0]];
    [range1 addEvent:events[1]];
    
    ZMEventIDRange *range2 = [[ZMEventIDRange alloc] init];
    [range2 addEvent:events[2]];
    [range2 addEvent:events[3]];
    
    ZMEventIDRange *window = [[ZMEventIDRange alloc] init];
    [window addEvent:events[0]];
    [window addEvent:events[0]];
    
    ZMEventIDRange *expectedGap = [[ZMEventIDRange alloc] init];
    [expectedGap addEvent:events[1]];
    [expectedGap addEvent:events[2]];
    
    // when
    ZMEventIDRangeSet *sut = [[ZMEventIDRangeSet alloc] initWithRanges:@[range1, range2]];
    
    // then
    XCTAssertNil([sut firstGapWithinWindow:window]);
}

- (void)testThatItSetsMessageWindowThatExtendsBeyondInterval
{
    // given
    NSArray* events = @[
                        [ZMEventID eventIDWithString:@"1.800122000a68f010"],
                        [ZMEventID eventIDWithString:@"5.800122000a68f005"],
                        [ZMEventID eventIDWithString:@"10.5"],
                        ];
    
    ZMEventIDRange *range1 = [[ZMEventIDRange alloc] init];
    [range1 addEvent:events[0]];
    [range1 addEvent:events[1]];
    
    ZMEventIDRange *window = [[ZMEventIDRange alloc] init];
    [window addEvent:events[0]];
    [window addEvent:events[2]];
    
    ZMEventIDRange *expectedGap = [[ZMEventIDRange alloc] init];
    [expectedGap addEvent:events[1]];
    [expectedGap addEvent:events[2]];
    
    ZMEventIDRangeSet *sut = [[ZMEventIDRangeSet alloc] initWithRanges:@[range1]];
    
    // when
    ZMEventIDRange *gap = [sut firstGapWithinWindow:window];
    
    // then
    XCTAssertEqualObjects(expectedGap, gap);
}

- (void)testThatFirstGapReturnsAGapWithMinorZeroIfTheOtherExtremeDoesNotHaveTheSameMajor
{
    // I don't want it to return 6e.0 - 6e.800112314201e38b
    // but 5.800112314201e200 - 6e.800112314201e38b is OK
    
    // given
    ZMEventID *event1 = [ZMEventID eventIDWithString:@"5.800112314201e200"];
    ZMEventID *event2 = [ZMEventID eventIDWithString:@"40.800112314201e38b"];
    ZMEventIDRange *range = [[ZMEventIDRange alloc] initWithEventIDs:@[event1, event2]];
    
    ZMEventID *windowEvent1 = [ZMEventID eventIDWithString:@"3.0"];
    ZMEventID *windowEvent2 = [ZMEventID eventIDWithString:@"30.800112314201e38b"];
    ZMEventIDRange *window = [[ZMEventIDRange alloc] initWithEventIDs:@[windowEvent1, windowEvent2]];
    
    ZMEventIDRangeSet *sut = [[ZMEventIDRangeSet alloc] initWithRanges:@[range]];
    
    
    // when
    ZMEventIDRange *gap = [sut firstGapWithinWindow:window];
    
    // then
    XCTAssertNotNil(gap);
    XCTAssertEqualObjects(gap.oldestMessage, windowEvent1);
    XCTAssertEqualObjects(gap.newestMessage, event1);
}

- (void)testThatFirstGapReturnsAGapIfTheExtremesHaveTheSameMajorButNotZeroAsMinor
{
    // I don't want it to return 6e.0 - 6e.800112314201e38b
    // but 5.800112314201e100 - 5.800112314201e200 is OK
    
    // given
    ZMEventID *event1 = [ZMEventID eventIDWithString:@"5.800112314201e200"];
    ZMEventID *event2 = [ZMEventID eventIDWithString:@"40.800112314201e38b"];
    ZMEventIDRange *range = [[ZMEventIDRange alloc] initWithEventIDs:@[event1, event2]];
    
    ZMEventID *windowEvent1 = [ZMEventID eventIDWithString:@"5.800112314201e100"];
    ZMEventID *windowEvent2 = [ZMEventID eventIDWithString:@"30.800112314201e38b"];
    ZMEventIDRange *window = [[ZMEventIDRange alloc] initWithEventIDs:@[windowEvent1, windowEvent2]];
    
    ZMEventIDRangeSet *sut = [[ZMEventIDRangeSet alloc] initWithRanges:@[range]];
    
    
    // when
    ZMEventIDRange *gap = [sut firstGapWithinWindow:window];
    
    // then
    XCTAssertNotNil(gap);
    XCTAssertEqualObjects(gap.oldestMessage, windowEvent1);
    XCTAssertEqualObjects(gap.newestMessage, event1);
}

- (void)testThatFirstGapReturnsNilIfTheTwoExtremesHaveTheSameMajorAndTheLowestHasMinorZero
{
    // I don't want it to return 6e.0 - 6e.800112314201e38b
    
    // given
    ZMEventID *event1 = [ZMEventID eventIDWithString:@"5.800112314201e200"];
    ZMEventID *event2 = [ZMEventID eventIDWithString:@"40.800112314201e38b"];
    ZMEventIDRange *range = [[ZMEventIDRange alloc] initWithEventIDs:@[event1, event2]];
    
    ZMEventID *windowEvent1 = [ZMEventID eventIDWithString:@"5.0"];
    ZMEventID *windowEvent2 = [ZMEventID eventIDWithString:@"30.800112314201e38b"];
    ZMEventIDRange *window = [[ZMEventIDRange alloc] initWithEventIDs:@[windowEvent1, windowEvent2]];
    
    ZMEventIDRangeSet *sut = [[ZMEventIDRangeSet alloc] initWithRanges:@[range]];
    
    
    // when
    ZMEventIDRange *gap = [sut firstGapWithinWindow:window];
    
    // then
    XCTAssertNil(gap);
}

- (void)testThatFirstGapReturnsAGapWithMinorZeroIfBothExtremesHaveMajorOneAndTheRangeIsEmpty
{
    // I don't want it to return 6e.0 - 6e.800112314201e38b
    // but 1.0 - 1.800112314201e38b is OK
    
    // given
    ZMEventID *windowEvent1 = [ZMEventID eventIDWithString:@"1.0"];
    ZMEventID *windowEvent2 = [ZMEventID eventIDWithString:@"1.800112314201e38b"];
    ZMEventIDRange *window = [[ZMEventIDRange alloc] initWithEventIDs:@[windowEvent1, windowEvent2]];
    
    ZMEventIDRangeSet *sut = [[ZMEventIDRangeSet alloc] init];
    
    // when
    ZMEventIDRange *gap = [sut firstGapWithinWindow:window];
    
    // then
    XCTAssertNotNil(gap);
    XCTAssertEqualObjects(gap.oldestMessage, windowEvent1);
    XCTAssertEqualObjects(gap.newestMessage, windowEvent2);
}

- (void)testThatFirstGapReturnsNilIfTheWindowIsNotValid
{
    // I don't want it to return 6e.0 - 6e.800112314201e38b
    
    // given
    ZMEventID *event1 = [ZMEventID eventIDWithString:@"5.800112314201e200"];
    ZMEventID *event2 = [ZMEventID eventIDWithString:@"40.800112314201e38b"];
    ZMEventIDRange *range = [[ZMEventIDRange alloc] initWithEventIDs:@[event1, event2]];
    
    ZMEventID *windowEvent1 = [ZMEventID eventIDWithString:@"10.0"];
    ZMEventID *windowEvent2 = [ZMEventID eventIDWithString:@"10.0"];
    ZMEventIDRange *window = [[ZMEventIDRange alloc] initWithEventIDs:@[windowEvent1, windowEvent2]];
    
    ZMEventIDRangeSet *sut = [[ZMEventIDRangeSet alloc] initWithRanges:@[range]];
    
    
    // when
    ZMEventIDRange *gap = [sut firstGapWithinWindow:window];
    
    // then
    XCTAssertNil(gap);
    
    //given
    windowEvent1 = [ZMEventID eventIDWithString:@"1.0"];
    windowEvent2 = [ZMEventID eventIDWithString:@"1.0"];
    window = [[ZMEventIDRange alloc] initWithEventIDs:@[windowEvent1, windowEvent2]];
    
    // when
    gap = [sut firstGapWithinWindow:window];
    
    // then
    XCTAssertNotNil(gap);
    
    //given
    windowEvent1 = [ZMEventID eventIDWithString:@"55.800112314201e200"];
    windowEvent2 = [ZMEventID eventIDWithString:@"55.800112314201e200"];
    window = [[ZMEventIDRange alloc] initWithEventIDs:@[windowEvent1, windowEvent2]];
    
    // when
    gap = [sut firstGapWithinWindow:window];
    
    // then
    XCTAssertNotNil(gap);
}


- (void)testThatLastGapReturnsAGapWithTheVeryFirstEventIDIfMissesTheBeginning;
{
    // given
    ZMEventID *event1 = [ZMEventID eventIDWithString:@"5.800112314201e200"];
    ZMEventID *event2 = [ZMEventID eventIDWithString:@"40.800112314201e38b"];
    ZMEventIDRange *range = [[ZMEventIDRange alloc] initWithEventIDs:@[event1, event2]];
    
    ZMEventID *windowEvent1 = [ZMEventID eventIDWithString:@"1.0"];
    ZMEventID *windowEvent2 = [ZMEventID eventIDWithString:@"30.800112314201e38b"];
    ZMEventIDRange *window = [[ZMEventIDRange alloc] initWithEventIDs:@[windowEvent1, windowEvent2]];
    
    ZMEventIDRangeSet *sut = [[ZMEventIDRangeSet alloc] initWithRanges:@[range]];
    
    
    // when
    ZMEventIDRange *gap = [sut lastGapWithinWindow:window];
    
    // then
    XCTAssertNotNil(gap);
    XCTAssertEqualObjects(gap.oldestMessage, [ZMEventID eventIDWithString:@"1.0"]);
    XCTAssertEqualObjects(gap.newestMessage, event1);
}

- (void)testThatLastGapReturnsTheNewestGapIfWindowContainsTwoGaps
{
    // given
    ZMEventID *event1 = [ZMEventID eventIDWithString:@"5.800112314201e200"];
    ZMEventID *event2 = [ZMEventID eventIDWithString:@"40.800112314201e38b"];
    ZMEventIDRange *range = [[ZMEventIDRange alloc] initWithEventIDs:@[event1, event2]];
    
    ZMEventID *windowEvent1 = [ZMEventID eventIDWithString:@"1.0"];
    ZMEventID *windowEvent2 = [ZMEventID eventIDWithString:@"50.800112314201e38b"];
    ZMEventIDRange *window = [[ZMEventIDRange alloc] initWithEventIDs:@[windowEvent1, windowEvent2]];
    
    ZMEventIDRangeSet *sut = [[ZMEventIDRangeSet alloc] initWithRanges:@[range]];
    
    
    // when
    ZMEventIDRange *gap = [sut lastGapWithinWindow:window];
    
    // then
    XCTAssertNotNil(gap);
    XCTAssertEqualObjects(gap.oldestMessage, event2);
    XCTAssertEqualObjects(gap.newestMessage, windowEvent2);
}

- (void)testThatLastGapReturnsTheWindowIfNoEventInRange
{
    // given
    ZMEventID *windowEvent1 = [ZMEventID eventIDWithString:@"1.0"];
    ZMEventID *windowEvent2 = [ZMEventID eventIDWithString:@"50.800112314201e38b"];
    ZMEventIDRange *window = [[ZMEventIDRange alloc] initWithEventIDs:@[windowEvent1, windowEvent2]];
    ZMEventIDRangeSet *sut = [[ZMEventIDRangeSet alloc] init];
    
    // when
    ZMEventIDRange *gap = [sut lastGapWithinWindow:window];
    
    // then
    XCTAssertNotNil(gap);
    XCTAssertEqualObjects(gap.oldestMessage, windowEvent1);
    XCTAssertEqualObjects(gap.newestMessage, windowEvent2);
}

- (void)testThatLastGapReturnsNilIfTheTwoExtremesHaveTheSameMajorAndTheLowestHasMinorZero
{
    // I don't want it to return 6e.0 - 6e.800112314201e38b
    
    // given
    ZMEventID *event1 = [ZMEventID eventIDWithString:@"5.800112314201e200"];
    ZMEventID *event2 = [ZMEventID eventIDWithString:@"40.800112314201e38b"];
    ZMEventIDRange *range = [[ZMEventIDRange alloc] initWithEventIDs:@[event1, event2]];
    
    ZMEventID *windowEvent1 = [ZMEventID eventIDWithString:@"5.0"];
    ZMEventID *windowEvent2 = [ZMEventID eventIDWithString:@"40.0"];
    ZMEventIDRange *window = [[ZMEventIDRange alloc] initWithEventIDs:@[windowEvent1, windowEvent2]];
    
    ZMEventIDRangeSet *sut = [[ZMEventIDRangeSet alloc] initWithRanges:@[range]];
    
    
    // when
    ZMEventIDRange *gap = [sut lastGapWithinWindow:window];
    
    // then
    XCTAssertNil(gap);
    
    // given
    event2 = [ZMEventID eventIDWithString:@"40.0"];
    range = [[ZMEventIDRange alloc] initWithEventIDs:@[event1, event2]];
    
    windowEvent2 = [ZMEventID eventIDWithString:@"40.800112314201e38b"];
    window = [[ZMEventIDRange alloc] initWithEventIDs:@[windowEvent1, windowEvent2]];
    
    sut = [[ZMEventIDRangeSet alloc] initWithRanges:@[range]];
    
    // when
    gap = [sut lastGapWithinWindow:window];
    
    // then
    XCTAssertNil(gap);
}

- (void)testThatLastGapReturnsNilIfTheWindowIsNotValid
{
    // I don't want it to return 6e.0 - 6e.800112314201e38b
    
    // given
    ZMEventID *event1 = [ZMEventID eventIDWithString:@"5.800112314201e200"];
    ZMEventID *event2 = [ZMEventID eventIDWithString:@"40.800112314201e38b"];
    ZMEventIDRange *range = [[ZMEventIDRange alloc] initWithEventIDs:@[event1, event2]];
    
    ZMEventID *windowEvent1 = [ZMEventID eventIDWithString:@"10.0"];
    ZMEventID *windowEvent2 = [ZMEventID eventIDWithString:@"10.0"];
    ZMEventIDRange *window = [[ZMEventIDRange alloc] initWithEventIDs:@[windowEvent1, windowEvent2]];
    
    ZMEventIDRangeSet *sut = [[ZMEventIDRangeSet alloc] initWithRanges:@[range]];
    
    
    // when
    ZMEventIDRange *gap = [sut lastGapWithinWindow:window];
    
    // then
    XCTAssertNil(gap);
    
    //given
    windowEvent1 = [ZMEventID eventIDWithString:@"1.0"];
    windowEvent2 = [ZMEventID eventIDWithString:@"1.0"];
    window = [[ZMEventIDRange alloc] initWithEventIDs:@[windowEvent1, windowEvent2]];
    
    // when
    gap = [sut lastGapWithinWindow:window];
    
    // then
    XCTAssertNotNil(gap);
    
    //given
    windowEvent1 = [ZMEventID eventIDWithString:@"55.800112314201e200"];
    windowEvent2 = [ZMEventID eventIDWithString:@"55.800112314201e200"];
    window = [[ZMEventIDRange alloc] initWithEventIDs:@[windowEvent1, windowEvent2]];
    
    // when
    gap = [sut lastGapWithinWindow:window];
    
    // then
    XCTAssertNotNil(gap);
}

- (void)testThatLastGapReturnsNilIfTheWindowEqualRange
{
    // I don't want it to return 6e.0 - 6e.800112314201e38b
    
    // given
    ZMEventID *event1 = [ZMEventID eventIDWithString:@"5.800112314201e200"];
    ZMEventID *event2 = [ZMEventID eventIDWithString:@"5.800112314201e200"];
    ZMEventIDRange *range = [[ZMEventIDRange alloc] initWithEventIDs:@[event1, event2]];
    
    ZMEventID *windowEvent1 = [ZMEventID eventIDWithString:@"5.800112314201e200"];
    ZMEventID *windowEvent2 = [ZMEventID eventIDWithString:@"5.800112314201e200"];
    ZMEventIDRange *window = [[ZMEventIDRange alloc] initWithEventIDs:@[windowEvent1, windowEvent2]];
    
    ZMEventIDRangeSet *sut = [[ZMEventIDRangeSet alloc] initWithRanges:@[range]];
    
    
    // when
    ZMEventIDRange *gap = [sut lastGapWithinWindow:window];
    
    // then
    XCTAssertNil(gap);
}


@end


@interface ZMEventIDRangeTests : ZMTBaseTest

@end

@implementation ZMEventIDRangeTests

- (void)testThatANewRangeIsEmpty
{
    // given
    ZMEventIDRange *sut = [[ZMEventIDRange alloc] init];
    
    // then
    XCTAssertTrue(sut.empty);
}

- (void)testThatContainsReturnsTheRightValue
{
    // given
    ZMEventIDRange *sut = [[ZMEventIDRange alloc] init];
    ZMEventID *event1 = [ZMEventID eventIDWithString:@"23.44"];
    ZMEventID *event2 = [ZMEventID eventIDWithString:@"23.48"];
    
    // when
    [sut addEvent:event1];
  
    // then
    XCTAssertTrue([sut containsEvent:event1]);
    XCTAssertFalse([sut containsEvent:event2]);
}

- (void)testThatWeCanAddAnEvent
{
    // given
    NSString *eventString = @"2.57a3";
    ZMEventIDRange *sut = [[ZMEventIDRange alloc] init];
    [sut addEvent:[ZMEventID eventIDWithString:eventString]];
    
    // then
    XCTAssertFalse(sut.empty);
    XCTAssertTrue([sut containsEvent:[ZMEventID eventIDWithString:eventString]]);
}

- (void)testThatWeCanMerge
{
    // given
    NSArray *eventStrings = @[@"2.2", @"2.3", @"3.3", @"4.4"];
    ZMEventIDRange *sut = [[ZMEventIDRange alloc] init];
    [sut addEvent:[ZMEventID eventIDWithString:eventStrings[0]]];
    [sut addEvent:[ZMEventID eventIDWithString:eventStrings[1]]];
    ZMEventIDRange *other = [[ZMEventIDRange alloc] init];
    [other addEvent:[ZMEventID eventIDWithString:eventStrings[2]]];
    [other addEvent:[ZMEventID eventIDWithString:eventStrings[3]]];
    
    // when
    [sut mergeRange:other];
    
    // then
    for (NSString *s in eventStrings) {
        XCTAssertTrue([sut containsEvent:[ZMEventID eventIDWithString:s]], @"%@", s);
    }
    XCTAssertFalse([sut containsEvent:[ZMEventID eventIDWithString:@"1.1"]]);
    XCTAssertFalse([sut containsEvent:[ZMEventID eventIDWithString:@"5.5"]]);
}

- (void)testThatItDoesNotCrashOnNil
{
    // given
    ZMEventIDRange *sut = [[ZMEventIDRange alloc] init];
    
    // when
    [sut addEvent:nil];
    [sut mergeRange:nil];
}

- (void)testThatIsComparesEqual
{
    // given
    NSArray *eventStrings = @[@"2.2", @"2.3", @"3.3", @"4.4"];
    ZMEventIDRange *sut = [[ZMEventIDRange alloc] init];
    [sut addEvent:[ZMEventID eventIDWithString:eventStrings[0]]];
    [sut addEvent:[ZMEventID eventIDWithString:eventStrings[1]]];
    ZMEventIDRange *other = [[ZMEventIDRange alloc] init];
    [other addEvent:[ZMEventID eventIDWithString:eventStrings[2]]];
    [other addEvent:[ZMEventID eventIDWithString:eventStrings[3]]];
    ZMEventIDRange *sutClone = [[ZMEventIDRange alloc] init];
    [sutClone addEvent:[ZMEventID eventIDWithString:eventStrings[0]]];
    [sutClone addEvent:[ZMEventID eventIDWithString:eventStrings[1]]];
    
    // then
    XCTAssertEqualObjects(sut,sutClone);
    XCTAssertEqualObjects(sut,sut);
    XCTAssertNotEqualObjects(sut, other);
    XCTAssertNotEqualObjects(sut, nil);
    XCTAssertNotEqualObjects(other, nil);
}

@end
