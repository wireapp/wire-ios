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


#import <XCTest/XCTest.h>
#import "AppController+Internal.h"


@interface AppControllerTests : XCTestCase

@property (nonatomic) AppController *sut;

@end


@implementation AppControllerTests

- (void)setUp
{
    [super setUp];
    self.sut = [[AppController alloc] init];
}

- (void)testThatItExecutesAppendedBlocksWhenUserSessionIsBeingInitialized
{
    // given
    __block NSUInteger blockExecutionCount = 0;

    [self.sut performAfterUserSessionIsInitialized:^{
        blockExecutionCount++;
    }];

    // assert that the block is not executed immediately
    [NSThread sleepForTimeInterval:0.1];
    XCTAssertEqual(blockExecutionCount, 0lu);

    // when
    [self.sut executeQueuedBlocksIfNeeded];
    [self.sut executeQueuedBlocksIfNeeded];

    // then
    XCTAssertEqual(blockExecutionCount, 1lu);
}

- (void)testThatItClearsBlocksToExecuteAfterExecuting
{
    // given
    __block BOOL blockCalled = NO;
    
    dispatch_block_t blockToExecute = ^{
        blockCalled = YES;
    };
    
    // when
    [self.sut performAfterUserSessionIsInitialized:blockToExecute];
    
    // assert that the block is not executed immediately
    [NSThread sleepForTimeInterval:0.1];
    XCTAssertFalse(blockCalled);
    
    // then
    XCTAssertEqual(self.sut.blocksToExecute.count, 1lu);
    XCTAssertEqualObjects(self.sut.blocksToExecute, @[blockToExecute]);
    
    // when
    [self.sut executeQueuedBlocksIfNeeded];
    
    // then
    XCTAssertTrue(blockCalled);
    XCTAssertEqual(self.sut.blocksToExecute.count, 0lu);
}

@end
