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


@import Foundation;
#import "MessagingTest.h"
#import "ZMChangedIndexes.h"
#import "ZMOrderedSetState.h"

@interface ZMChangedIndexesTests : MessagingTest




@end

@implementation ZMChangedIndexesTests



- (void)testThatItCalculatesDifferenceBetweenOrderedSets
{

    // given
    ZMOrderedSetState *startState = [[ZMOrderedSetState alloc] initWithOrderedSet:[[NSOrderedSet alloc] initWithObjects:@"A", @"B", @"C", @"D", @"E", nil]];

    ZMOrderedSetState *endState = [[ZMOrderedSetState alloc] initWithOrderedSet:[[NSOrderedSet alloc] initWithObjects:@"A", @"F", @"D", @"C", @"E", nil]];
    
    ZMOrderedSetState *updateState = [[ZMOrderedSetState alloc] initWithOrderedSet:[[NSOrderedSet alloc] initWithObjects:@"C", @"E", nil]];
    
    
    // when
    ZMChangedIndexes *sut = [[ZMChangedIndexes alloc] initWithStartState:startState endState:endState updatedState:updateState];
    
    
    // then
    XCTAssertEqualObjects(sut.deletedIndexes, [[NSIndexSet alloc] initWithIndex:1]);
    XCTAssertEqualObjects(sut.insertedIndexes, [[NSIndexSet alloc] initWithIndex:1]);
    
    XCTAssertEqualObjects(sut.updatedIndexes, [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(3, 2)]);
    
    __block BOOL calledOnce = NO;
    [sut enumerateMovedIndexes:^(NSUInteger from, NSUInteger to) {
        XCTAssertFalse(calledOnce);
        calledOnce = YES;
        XCTAssertEqual(from, 3u);
        XCTAssertEqual(to, 2u);
    }];
    
    XCTAssertTrue(calledOnce);
}

- (void)testThatItCalculatesMovedIndexesForSwappedIndexesCorrectly
{
    
    // given
    ZMOrderedSetState *startState = [[ZMOrderedSetState alloc] initWithOrderedSet:[[NSOrderedSet alloc] initWithObjects:@"A", @"B", @"C", nil]];
    ZMOrderedSetState *endState = [[ZMOrderedSetState alloc] initWithOrderedSet:[[NSOrderedSet alloc] initWithObjects:@"C", @"B", @"A", nil]];
    ZMOrderedSetState *updateState = [[ZMOrderedSetState alloc] initWithOrderedSet:[NSOrderedSet orderedSet]];
    
    // when
    ZMChangedIndexes *sut = [[ZMChangedIndexes alloc] initWithStartState:startState endState:endState updatedState:updateState];
    
    // then
    XCTAssertEqualObjects(sut.deletedIndexes, [NSIndexSet indexSet]);
    XCTAssertEqualObjects(sut.insertedIndexes, [NSIndexSet indexSet]);
    XCTAssertEqualObjects(sut.updatedIndexes, [NSIndexSet indexSet]);

    __block NSUInteger callcount = 0;
    [sut enumerateMovedIndexes:^(NSUInteger from, NSUInteger to) {
        if (callcount == 0) {
            XCTAssertEqual(from, 2u);
            XCTAssertEqual(to, 0u);
        } if (callcount == 1) {
            XCTAssertEqual(from, 2u);
            XCTAssertEqual(to, 1u);
        } 
        callcount++;
    }];

    XCTAssertEqual(callcount, 2u);
}


@end
