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
    [self disableMultibackend];
    self.pushChannelNotifications = [NSMutableArray array];
    
    self.cookieStorage = [[FakeCookieStorage alloc] init];
    self.mockPushChannel = [[MockPushChannel alloc] init];
    self.mockTransportSesssion = [[RecordingMockTransportSession alloc] initWithCookieStorage:self.cookieStorage
                                                                                  pushChannel:self.mockPushChannel];
            
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
                                                      apiVersion:nil];
    self.pushChannelObserverToken = [NotificationInContext addObserverWithNotificationCenter:[NSNotificationCenter defaultCenter]
                                                                                        name:ZMOperationLoop.pushChannelStateChangeNotificationName
                                                                                     context:self.uiMOC.notificationContext
                                                                                      object:nil
                                                                                       queue:nil
                                                                                       using:^(NotificationInContext * note) {
        [self pushChannelDidChange:note];
    }];
}

- (void)tearDown;
{
    WaitForAllGroupsToBeEmpty(0.5);
    self.pushChannelObserverToken = nil;
    self.pushNotificationStatus = nil;
    self.applicationStatusDirectory = nil;
    self.mockPushChannel = nil;
    self.mockTransportSesssion = nil;
    self.mockRequestStrategy = nil;
    self.mockUpdateEventProcessor = nil;
    [self.sut tearDown];
    self.sut = nil;

    [super tearDown];
}

- (void)pushChannelDidChange:(NotificationInContext *)note
{
    [self.pushChannelNotifications addObject:note];
}

- (void)testThatItNotifiesTheSyncStatus_WhenThePushChannelIsOpened
{
    // when
    [(id<ZMPushChannelConsumer>)self.sut pushChannelDidOpen];
    
    // then
    XCTAssertNotNil(self.syncStatus.pushChannelEstablishedDate);
}

- (void)testThatItNotifiesTheSyncStatus_WhenThePushChannelIsClosed
{
    // given
    [(id<ZMPushChannelConsumer>)self.sut pushChannelDidOpen];
    
    // when
    [(id<ZMPushChannelConsumer>)self.sut pushChannelDidClose];
    
    // then
    XCTAssertNil(self.syncStatus.pushChannelEstablishedDate);
}

- (void)testThatItInitializesThePushChannel
{
    // when
    ZMOperationLoop *op = [[ZMOperationLoop alloc] initWithTransportSession:self.mockTransportSesssion
                                                            requestStrategy:self.mockRequestStrategy
                                                       updateEventProcessor:self.mockUpdateEventProcessor
                                                            operationStatus:self.operationStatus
                                                                 syncStatus:self.syncStatus
                                                     pushNotificationStatus:self.pushNotificationStatus
                                                                      uiMOC:self.uiMOC
                                                                    syncMOC:self.syncMOC
                                                     isDeveloperModeEnabled:NO
                                                            isSyncV2Enabled:NO
                                                                 apiVersion:nil];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertNotNil(op);
    XCTAssertTrue(self.mockTransportSesssion.didCallConfigurePushChannel);
    [op tearDown];
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
    [self setBackendInfoAPIVersionNil];
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


- (void)testThatPushChannelDataBuffered_WhenSyncing
{
    // given
    NSString *eventType = @"user.update";
    
    NSDictionary *payload1 = @{
                               @"type" : eventType,
                               @"foo" : @"bar"
                               };
    NSDictionary *payload2 = @{
                               @"type" : eventType,
                               @"bar" : @"xxxxxxx"
                               };
    NSDictionary *payload3 = @{
                               @"type" : eventType,
                               @"baz" : @"barbar"
                               };
    
    NSDictionary *eventData = @{
                                @"id" : @"5cc1ab91-45f4-49ec-bb7a-a5517b7a4173",
                                @"payload" : @[payload1, payload2, payload3],
                                };

    NSMutableArray *expectedEvents = [NSMutableArray array];
    [expectedEvents addObjectsFromArray:[ZMUpdateEvent eventsArrayFromPushChannelData:eventData]];
    XCTAssertGreaterThan(expectedEvents.count, 0u);

    // when
    NSData *pushChannelData = [NSJSONSerialization dataWithJSONObject:eventData
                                                              options:0
                                                                error:nil];

    [(id<ZMPushChannelConsumer>)self.sut pushChannelDidReceiveData:pushChannelData];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(self.mockUpdateEventProcessor.bufferedEvents, expectedEvents);
}

- (void)testThatPushChannelDataProcessed_WhenOnline
{
    // given

    // FIXME: [WPB-9091] use a mock sync status
    // simulate being online
    [self.syncStatus pushChannelDidOpen];
    while (self.syncStatus.isSyncing) {
        [self.syncStatus finishCurrentSyncPhaseWithPhase:self.syncStatus.currentSyncPhase];
    }

    NSString *eventType = @"user.update";

    NSDictionary *payload1 = @{
                               @"type" : eventType,
                               @"foo" : @"bar"
                               };
    NSDictionary *payload2 = @{
                               @"type" : eventType,
                               @"bar" : @"xxxxxxx"
                               };
    NSDictionary *payload3 = @{
                               @"type" : eventType,
                               @"baz" : @"barbar"
                               };

    NSDictionary *eventData = @{
                                @"id" : @"5cc1ab91-45f4-49ec-bb7a-a5517b7a4173",
                                @"payload" : @[payload1, payload2, payload3],
                                };

    NSMutableArray *expectedEvents = [NSMutableArray array];
    [expectedEvents addObjectsFromArray:[ZMUpdateEvent eventsArrayFromPushChannelData:eventData]];
    XCTAssertGreaterThan(expectedEvents.count, 0u);

    // when
    NSData *pushChannelData = [NSJSONSerialization dataWithJSONObject:eventData
                                                              options:0
                                                                error:nil];

    [(id<ZMPushChannelConsumer>)self.sut pushChannelDidReceiveData:pushChannelData];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqualObjects(self.mockUpdateEventProcessor.processedLivedEvents, expectedEvents);
}

- (void)testThatProcessSyncDataIsNotForwardedToAllSyncObjectsIfItIsNotAnArray
{
    // given
    NSDictionary *eventData = @{
                                @"id" : @"16be010d-c284-4fc0-b636-837bcebed654",
                                @"payload" : @{
                                        @"type" : @"yyy",
                                        @"cat" : @"dog"
                                        },
                                };
    
    // when
    NSData *pushChannelData = [NSJSONSerialization dataWithJSONObject:eventData
                                                              options:0
                                                                error:nil];

    [self performIgnoringZMLogError:^{
        [(id<ZMPushChannelConsumer>)self.sut pushChannelDidReceiveData:pushChannelData];
        WaitForAllGroupsToBeEmpty(0.5);
    }];
    
    // then
    XCTAssertEqual(self.mockUpdateEventProcessor.processedEvents.count, 0);
}

- (void)testThatProcessSyncDataIsNotForwardedToAllSyncObjectsIfEventsAreInvalid
{
    // given
    NSArray *eventData = @[ @{ @"id" : @"16be010d-c284-4fc0-b636-837bcebed654" } ];

    // when
    NSData *pushChannelData = [NSJSONSerialization dataWithJSONObject:eventData
                                                              options:0
                                                                error:nil];

    [self performIgnoringZMLogError:^{
        [(id<ZMPushChannelConsumer>)self.sut pushChannelDidReceiveData:pushChannelData];
        WaitForAllGroupsToBeEmpty(0.5);
    }];
    
    // then
    XCTAssertEqual(self.mockUpdateEventProcessor.processedEvents.count, 0);
}

- (void)testThatItSendsANotificationWhenClosingThePushChannelAndRemovingConsumers
{
    // when
    [(id<ZMPushChannelConsumer>)self.sut pushChannelDidClose];
    
    // then
    XCTAssertEqual(self.pushChannelNotifications.count, 1u);
    NSNotification *note = self.pushChannelNotifications.firstObject;
    XCTAssertFalse([note.userInfo[ZMPushChannelIsOpenKey] boolValue]);
}

- (void)testThatItSendsANotificationWhenOpeningThePushChannel
{
    // when
    [(id<ZMPushChannelConsumer>)self.sut pushChannelDidOpen];
    
    // then
    XCTAssertEqual(self.pushChannelNotifications.count, 1u);
    NSNotification *note = self.pushChannelNotifications.firstObject;
    XCTAssertTrue([note.userInfo[ZMPushChannelIsOpenKey] boolValue]);
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
