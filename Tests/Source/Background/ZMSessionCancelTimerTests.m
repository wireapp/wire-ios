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


@import XCTest;
@import WireTesting;

#import <WireTransport/WireTransport-Swift.h>
#import "WireTransport_ios_tests-Swift.h"

#import "ZMSessionCancelTimer.h"
#import "ZMSessionCancelTimer+Internal.h"
#import "ZMURLSession.h"
#import "ZMTransportSession.h"

@interface ZMSessionCancelTimerTests : XCTestCase

@property (nonatomic, strong) MockBackgroundActivityManager *activityManager;

@end

@implementation ZMSessionCancelTimerTests

- (void)setUp
{
    [super setUp];
    self.activityManager = [[MockBackgroundActivityManager alloc] init];
    BackgroundActivityFactory.sharedFactory.mainQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0);
    BackgroundActivityFactory.sharedFactory.activityManager = self.activityManager;
}

- (void)tearDown
{
    self.activityManager = nil;
    [BackgroundActivityFactory.sharedFactory reset];
    [super tearDown];
}

- (void)testThatItCancelsATask
{
    // GIVEN
    ZMMockURLSession *session = [ZMMockURLSession createMockSession];
    ZMSessionCancelTimer *sut = [[ZMSessionCancelTimer alloc] initWithURLSession:session timeout:0.05];

    // EXPECTATIONS
    __block XCTestExpectation *cancelledCalledExpectation = [self expectationWithDescription:@"requests are cancelled"];

    session.cancellationHandler = ^{
        [cancelledCalledExpectation fulfill];
    };

    // WHEN
    [sut start];

    // THEN
    [self waitForExpectations:@[cancelledCalledExpectation] timeout:5];
}

- (void)testThatItNotifiesTheOperationLoopAfterAllTasksHaveBeenCancelled;
{
    // GIVEN
    ZMMockURLSession *session = [ZMMockURLSession createMockSession];
    ZMSessionCancelTimer *sut = [[ZMSessionCancelTimer alloc] initWithURLSession:session timeout:0.05];

    // EXPECTATIONS
    XCTestExpectation *newRequestsExpectation = [self expectationForNotification:ZMTransportSessionNewRequestAvailableNotification
                                                                          object:nil
                                                                         handler:nil];

    // WHEN
    [sut start];

    // THEN
    [self waitForExpectations:@[newRequestsExpectation] timeout:5];
}

- (void)testThatItBeginsABackgroundActivityWhenStarting
{
    // GIVEN
    ZMURLSession *session = [OCMockObject mockForClass:ZMURLSession.class];
    ZMSessionCancelTimer *sut = [[ZMSessionCancelTimer alloc] initWithURLSession:session timeout:1.0];

    // WHEN
    [sut start];

    // THEN
    XCTAssertTrue(BackgroundActivityFactory.sharedFactory.isActive);
    XCTAssertEqual(self.activityManager.numberOfTasks, 1);
}

- (void)testThatItEndsTheActivityAfterAllTasksHaveBeenCancelled;
{
    // GIVEN
    ZMMockURLSession *session = [ZMMockURLSession createMockSession];
    ZMSessionCancelTimer *sut = [[ZMSessionCancelTimer alloc] initWithURLSession:session timeout:0.05];

    // EXPECTATIONS
    __block XCTestExpectation *taskCancelledExpectation = [self expectationWithDescription:@"the background task is ended"];

    self.activityManager.endTaskHandler = ^(NSString * _Nullable name) {
        NOT_USED(name);
        [taskCancelledExpectation fulfill];
    };

    // WHEN
    [sut start];

    // THEN
    [self waitForExpectations:@[taskCancelledExpectation] timeout:0.5];
}

- (void)testThatItDoesntStartTheTimerIfTheAppIsBeingSuspended
{
    // GIVEN
    ZMMockURLSession *session = [ZMMockURLSession createMockSession];
    ZMSessionCancelTimer *sut = [[ZMSessionCancelTimer alloc] initWithURLSession:session timeout:0.05];
    [self.activityManager triggerExpiration];

    // EXPECTATIONS
    __block XCTestExpectation *cancelledCalledExpectation = [self expectationWithDescription:@"network requests are cancelled"];

    __block XCTestExpectation *taskCreatedExpectation = [self expectationWithDescription:@"the background task is not started"];
    taskCreatedExpectation.inverted = YES;

    session.cancellationHandler = ^{
        [cancelledCalledExpectation fulfill];
    };

    self.activityManager.startTaskHandler = ^(NSString * _Nullable name) {
        NOT_USED(name);
        [taskCreatedExpectation fulfill];
    };

    // WHEN
    [sut start];
    XCTAssertEqual(sut.timer.state, ZMTimerStateNotStarted);
    XCTAssertEqual(self.activityManager.numberOfTasks, 0);

    // THEN
    [self waitForExpectations:@[cancelledCalledExpectation, taskCreatedExpectation] timeout:1];
}

- (void)testThatItEndsTheBackgroundTaskWhenItIsCancelled;
{
    // GIVEN
    ZMMockURLSession *session = [ZMMockURLSession createMockSession];
    ZMSessionCancelTimer *sut = [[ZMSessionCancelTimer alloc] initWithURLSession:session timeout:10];

    // EXPECTATIONS
    __block XCTestExpectation *taskEndedExpectation = [self expectationWithDescription:@"the background task is ended"];

    self.activityManager.endTaskHandler = ^(NSString * _Nullable name) {
        NOT_USED(name);
        [taskEndedExpectation fulfill];
    };

    // WHEN
    [sut start];
    [sut cancel];

    // THEN
    [self waitForExpectations:@[taskEndedExpectation] timeout:5];
}

- (void)testThatItCancelsWhenTheApplicationCallsTheExpirationTimer
{
    // GIVEN
    ZMMockURLSession *session = [ZMMockURLSession createMockSession];
    ZMSessionCancelTimer *sut = [[ZMSessionCancelTimer alloc] initWithURLSession:session timeout:10];

    // EXPECTATIONS
    __block XCTestExpectation *cancelledCalledExpectation = [self expectationWithDescription:@"requests are cancelled"];

    session.cancellationHandler = ^{
        [cancelledCalledExpectation fulfill];
    };

    // WHEN
    [sut start];
    [self.activityManager triggerExpiration];

    // THEN
    [self waitForExpectations:@[cancelledCalledExpectation] timeout:5];
}

@end
