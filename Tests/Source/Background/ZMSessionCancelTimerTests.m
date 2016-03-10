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


@import XCTest;
@import ZMTesting;
@import OCMock;

#import "ZMSessionCancelTimer.h"
#import "ZMURLSession.h"
#import "ZMBackgroundActivity.h"
#import "ZMTransportSession.h"

@interface ZMSessionCancelTimerTests : ZMTBaseTest

@end

@implementation ZMSessionCancelTimerTests

- (void)testThatItCancelsATask
{
    // given
    ZMURLSession *session = [OCMockObject mockForClass:ZMURLSession.class];
    ZMSessionCancelTimer *sut = [[ZMSessionCancelTimer alloc] initWithURLSession:session timeout:0.05];
    NOT_USED(sut);
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"cancel was called"];
    
    // expectations
    [[[(OCMockObject *)session expect] andDo:^(NSInvocation *inv) {
        NOT_USED(inv);
        [expectation1 fulfill];
    }] cancelAllTasksWithCompletionHandler:[OCMArg checkWithBlock:^BOOL(dispatch_block_t block) {
        block();
        return YES;
    }]];
    
    // when
    [sut start];
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
    
    // then
    [(OCMockObject *)session verify];
}

- (void)testThatItNotifiesTheOperationLoopAfterAllTasksHaveBeenCancelled;
{
    // given
    id session = [OCMockObject mockForClass:ZMURLSession.class];
    ZMSessionCancelTimer *sut = [[ZMSessionCancelTimer alloc] initWithURLSession:session timeout:0.05];
    id mockLoop = [OCMockObject mockForClass:ZMTransportSession.class];
    
    NOT_USED(sut);
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"operation loop invoked"];
    
    // expectations
    [[session stub] cancelAllTasksWithCompletionHandler:[OCMArg checkWithBlock:^BOOL(dispatch_block_t block) {
        block();
        return YES;
    }]];
    [[[mockLoop stub] andDo:^(NSInvocation *inv) {
        NOT_USED(inv);
        [expectation1 fulfill];
    }] notifyNewRequestsAvailable:OCMOCK_ANY];
    
    // when
    [sut start];
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatItEndsTheActivityAfterAllTasksHaveBeenCancelled;
{
    // TODO DANIEL
}

- (void)testThatItOnlyCancelsTasksAfterTheTimeout
{
    // given
    ZMURLSession *session = [OCMockObject mockForClass:ZMURLSession.class];
    ZMSessionCancelTimer *sut = [[ZMSessionCancelTimer alloc] initWithURLSession:session timeout:0.05];
    NOT_USED(sut);
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"cancel was called"];

    // expectations
    [[[(OCMockObject *)session stub] andDo:^(NSInvocation *inv) {
        NOT_USED(inv);
        [expectation1 fulfill];
    }] cancelAllTasksWithCompletionHandler:[OCMArg checkWithBlock:^BOOL(dispatch_block_t block) {
        block();
        return YES;
    }]];
    
    // when
    [sut start];
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);

}

- (void)testThatItBeginsABackgroundActivityWhenStarting
{
    // given
    ZMBackgroundActivity *backgroundActivity = [OCMockObject mockForClass:ZMBackgroundActivity.class];
    
    ZMURLSession *session = [OCMockObject mockForClass:ZMURLSession.class];
    ZMSessionCancelTimer *sut = [[ZMSessionCancelTimer alloc] initWithURLSession:session timeout:1.0];
    
    // expect
    [[[(OCMockObject *)backgroundActivity expect] classMethod] beginBackgroundActivityWithName:OCMOCK_ANY];
    
    // when
    [sut start];
    
    // then
    [(OCMockObject *)backgroundActivity verify];
    [(OCMockObject *)backgroundActivity stopMocking];
}

- (void)testThatitEndsTheBackgroundActivityWhenItIsCancelled;
{
    // given
    ZMBackgroundActivity *backgroundActivity = [OCMockObject mockForClass:ZMBackgroundActivity.class];
    ZMURLSession *session = [OCMockObject mockForClass:ZMURLSession.class];
    ZMSessionCancelTimer *sut = [[ZMSessionCancelTimer alloc] initWithURLSession:session timeout:2];
    
    NOT_USED(sut);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"cancel was called"];
    
    id activity = [OCMockObject mockForClass:ZMBackgroundActivity.class];
    [[[[(OCMockObject *)backgroundActivity expect] classMethod] andReturn:activity] beginBackgroundActivityWithName:OCMOCK_ANY];
    
    // expectations
    [[(OCMockObject *)session stub] cancelAllTasksWithCompletionHandler:[OCMArg checkWithBlock:^BOOL(dispatch_block_t block) {
        block();
        return YES;
    }]];
    [[[activity expect] andDo:^(NSInvocation *inv) {
        NOT_USED(inv);
        [expectation fulfill];
    }] endActivity];
    
    
    // when
    [sut start];
    [sut cancel];
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
    
    // then
    [(OCMockObject *)backgroundActivity stopMocking];
    [(OCMockObject *)backgroundActivity verify];
    [activity verify];
}

- (void)testThatItEndsABackgroundActivityWhenTheTimerFires
{
    // given
    ZMBackgroundActivity *backgroundActivity = [OCMockObject mockForClass:ZMBackgroundActivity.class];
    ZMURLSession *session = [OCMockObject niceMockForClass:ZMURLSession.class];
    ZMSessionCancelTimer *sut = [[ZMSessionCancelTimer alloc] initWithURLSession:session timeout:0.05];
    
    NOT_USED(sut);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"cancel was called"];
    
    id activity = [OCMockObject mockForClass:ZMBackgroundActivity.class];
    [[[[(OCMockObject *)backgroundActivity expect] classMethod] andReturn:activity] beginBackgroundActivityWithName:OCMOCK_ANY];
    
    // expectations
    [[(OCMockObject *)session stub] cancelAllTasksWithCompletionHandler:[OCMArg checkWithBlock:^BOOL(dispatch_block_t block) {
        block();
        return YES;
    }]];
    [[[activity expect] andDo:^(NSInvocation *inv) {
        NOT_USED(inv);
        [expectation fulfill];
    }] endActivity];

    
    // when
    [sut start];
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
    
    // then
    [(OCMockObject *)backgroundActivity stopMocking];
    [(OCMockObject *)backgroundActivity verify];
    [activity verify];
}

@end
