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

#import "MessagingTest.h"
#import "ZMSyncStrategy.h"
#import "Tests-Swift.h"
#import "MockModelObjectContextFactory.h"
#import "ZMOperationLoop+Private.h"
#import "ZMSyncStrategy+Internal.h"
#import "ZMSyncStrategy+ManagedObjectChanges.h"
#import "ZMOperationLoopTests.h"

@implementation ZMOperationLoopTests;

- (void)setUp
{
    [super setUp];
    
    self.cookieStorage = [[FakeCookieStorage alloc] init];
    self.mockTransportSesssion = [[RecordingMockTransportSession alloc] initWithCookieStorage:self.cookieStorage];
            
    self.mockRequestStrategy = [[MockRequestStrategy alloc] init];
    self.mockUpdateEventProcessor = [[MockUpdateEventProcessor alloc] init];
    self.mockRequestCancellation = [[MockRequestCancellation alloc] init];

    self.operationStatus = [[OperationStatus alloc] init];
    self.syncStatus = [[SyncStatus alloc] initWithManagedObjectContext:self.syncMOC lastEventIDRepository:self.lastEventIDRepository isSyncV2Enabled:NO];
    self.pushNotificationStatus = [[PushNotificationStatus alloc] initWithManagedObjectContext:self.syncMOC lastEventIDRepository:self.lastEventIDRepository];
    self.sut = [[ZMOperationLoop alloc] initWithTransportSession:self.mockTransportSesssion
                                                 requestStrategy:self.mockRequestStrategy
                                            updateEventProcessor:self.mockUpdateEventProcessor
                                                 operationStatus:self.operationStatus
                                                      syncStatus:self.syncStatus
                                          pushNotificationStatus:self.pushNotificationStatus
                                                           uiMOC:self.uiMOC
                                                         syncMOC:self.syncMOC
                                          isDeveloperModeEnabled:NO
                                                 isSyncV2Enabled:NO
                                                      apiVersion:@5];
}

- (void)tearDown;
{
    WaitForAllGroupsToBeEmpty(0.5);
    self.pushNotificationStatus = nil;
    self.applicationStatusDirectory = nil;
    self.mockTransportSesssion = nil;
    self.mockRequestStrategy = nil;
    self.mockUpdateEventProcessor = nil;
    [self.sut tearDown];
    self.sut = nil;

    [super tearDown];
}

- (void)testThatItSendsTheNextOperation
{

    // given
    ZMTransportRequest *request = [[ZMTransportRequest alloc] initWithPath:@"/test"
                                                                   method:ZMTransportRequestMethodPost
                                                                  payload:@{@"foo": @"bar"}
                                                                apiVersion:0];
    self.mockRequestStrategy.mockRequest = request;

    // when
    [ZMRequestAvailableNotification notifyNewRequestsAvailable:self];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(self.mockRequestStrategy.nextRequestCalled);
    XCTAssertEqualObjects(self.mockTransportSesssion.lastEnqueuedRequest, request);
}

- (void)testThatItDoesNotSendARequestIfThereAreNone
{
    // given
    self.mockRequestStrategy.mockRequest = nil;
    
    // when
    [ZMRequestAvailableNotification notifyNewRequestsAvailable:self];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertNil(self.mockTransportSesssion.lastEnqueuedRequest);
}

- (void)testThatItDoesNotSendARequestIfThereIsNoCurrentAPIVersion
{
    // given
    [self.sut setApiVersion:nil];
    XCTAssertNil(self.sut.currentAPIVersion);

    self.mockRequestStrategy.mockRequest = [[ZMTransportRequest alloc] initWithPath:@"/test"
                                                                             method:ZMTransportRequestMethodPost
                                                                            payload:@{@"foo": @"bar"}
                                                                          apiVersion:0];

    // when
    [ZMRequestAvailableNotification notifyNewRequestsAvailable:self];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertFalse(self.mockRequestStrategy.nextRequestCalled);
    XCTAssertNil(self.mockTransportSesssion.lastEnqueuedRequest);
}

- (void)testThatItSendsAsManyCallsAsTheTransportSessionCanHandle
{
    // given
    ZMTransportRequest *request = [[ZMTransportRequest alloc] initWithPath:@"/test" method:ZMTransportRequestMethodPost payload:@{} apiVersion:0];
    self.mockRequestStrategy.mockRequestQueue = @[request, request, request];

    // when
    [ZMRequestAvailableNotification notifyNewRequestsAvailable:self];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqual(self.mockRequestStrategy.mockRequestQueue.count, 0);
}

- (void)testThatExecuteNextOperationIsCalledWhenThePreviousRequestIsCompleted
{
    // given
    ZMTransportRequest *request = [ZMTransportRequest requestWithPath:@"/boo" method:ZMTransportRequestMethodGet payload:nil apiVersion:0];
    self.mockRequestStrategy.mockRequest = request;
    [ZMRequestAvailableNotification notifyNewRequestsAvailable:self]; // this will enqueue `request`
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    self.mockRequestStrategy.nextRequestCalled = NO;
    [request completeWithResponse:[ZMTransportResponse responseWithPayload:@{} HTTPStatus:200 transportSessionError:nil apiVersion:0]];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(self.mockRequestStrategy.nextRequestCalled);

}

- (void)testThatItAsksSyncStrategyForNextOperationOnZMOperationLoopNewRequestAvailableNotification
{
    // when
    [ZMRequestAvailableNotification notifyNewRequestsAvailable:self];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(self.mockRequestStrategy.nextRequestCalled);
}

- (void)testThatItInformsTransportSessionWhenEnteringForeground
{
    // when
    [self.sut operationStatusDidChangeState:SyncEngineOperationStateForeground];
    
    // then
    XCTAssertTrue(self.mockTransportSesssion.didCallEnterForeground);
}

- (void)testThatItInformsTransportSessionWhenEnteringBackground
{
    // when
    [self.sut operationStatusDidChangeState:SyncEngineOperationStateBackground];
    
    // then
    XCTAssertTrue(self.mockTransportSesssion.didCallEnterBackground);
}

@end
