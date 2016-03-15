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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


#import "IntegrationTestBase.h"
#import "ZMUser.h"
#import "ZMUserSession.h"
#import "ZMUserSession+Internal.h"

#import "ZMConversation+Internal.h"

#import "ZMUserSession+Background+Testing.h"

@interface APNSTests : IntegrationTestBase

@end

@implementation APNSTests

- (NSDictionary *)APNSPayloadForNotificationPayload:(NSDictionary *)notificationPayload identifier:(NSUUID *)identifier {
    
    return @{ @"aps" :
                  @{
                      @"content-available" : @(1)
                      },
              @"data" :
                  @{
                      @"data": @{
                              @"id" : identifier ? identifier.transportString : @"bf96c4ce-c7d1-11e4-8001-22000a5a00c8",
                              @"payload" : @[notificationPayload],
                              @"transient" : @(0)
                              }
                      }
              };
    
}


- (NSDictionary *)APNSPayloadForNotificationPayload:(NSDictionary *)notificationPayload {
    
    return [self APNSPayloadForNotificationPayload:notificationPayload identifier:nil];
    
}


- (void)testThatAConversationIsCreatedFromAnAPNS
{
    // given
    BOOL const useAPNS = YES;
    
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    NSString *conversationName = @"MYCONVO";
    __block NSString *conversationID;
    WaitForAllGroupsToBeEmpty(0.2);
    __block NSDictionary *conversationTransportData;
    
    ZMConversationList *conversationsList = [ZMConversationList conversationsInUserSession:self.userSession];
    NSUInteger oldCount = conversationsList.count;
    
    if(useAPNS) {
        [self.mockTransportSession closePushChannelAndRemoveConsumer]; // do not use websocket
    }
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        MockConversation *conversation = [session insertGroupConversationWithSelfUser:self.selfUser otherUsers:@[self.user1]];
        [conversation changeNameByUser:self.selfUser name:conversationName];
        conversationID = conversation.identifier;
        conversationTransportData = (NSDictionary *)conversation.transportData;
    }];
    WaitForAllGroupsToBeEmpty(0.2);
    
    NSDictionary *payload = @{
                              @"conversation" : conversationID,
                              @"data" : conversationTransportData,
                              
                              @"from" : self.user1.identifier,
                              @"time" : @"2015-03-11T09:34:00.436Z",
                              @"type" : @"conversation.create"
                              };
    
    // expect
    [[[(id)self.userSession.application stub] andReturnValue:OCMOCK_VALUE(UIApplicationStateBackground)] applicationState];
    
    // when
    if(useAPNS) {
        [self.userSession receivedPushNotificationWithPayload:[self APNSPayloadForNotificationPayload:payload] completionHandler:nil source:ZMPushNotficationTypeVoIP];
    }
    WaitForAllGroupsToBeEmpty(0.2);
    
    // then
    ZMConversationList *convs = [ZMConversationList conversationsInUserSession:self.userSession];
    XCTAssertEqual(convs.count, oldCount+1);
    NSUInteger index = [conversationsList indexOfObjectPassingTest:^BOOL(ZMConversation *conversation, NSUInteger idx, BOOL *stop) {
        NOT_USED(idx);
        NOT_USED(stop);
        return [conversation.displayName isEqualToString:conversationName];
    }];
    XCTAssertNotEqual(index, (NSUInteger) NSNotFound);
    
}

- (void)testThatItDeletesAPushTokenWhenRequested
{
    // given
    XCTAssert([self logInAndWaitForSyncToBeComplete]);
    
    NSData *deviceToken = [NSData dataWithBytes:@"lalala" length:6];
    [self.mockTransportSession resetReceivedRequests];

    [self.userSession performChanges:^{
        [self.userSession application:self.userSession.application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    ZMTransportRequest *registrationRequest = self.mockTransportSession.receivedRequests.lastObject;
    NSString *encodedToken = registrationRequest.payload[@"token"];
    XCTAssertNotNil(encodedToken);
    
    self.mockTransportSession.responseGeneratorBlock = nil;
    [self.mockTransportSession resetReceivedRequests];
    
    
    // expect
    XCTestExpectation *deletionExpectation = [self expectationWithDescription:@"token deletion"];
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request) {
        NSString *path = [NSString pathWithComponents:@[@"/push/tokens", encodedToken]];
        if ([request.path isEqualToString:path] && request.method == ZMMethodDELETE) {
            [deletionExpectation fulfill];
            return nil;
        };
        return nil;
    };
    
    // when
    [self.userSession performChanges:^{
        [self.userSession removeRemoteNotificationTokenIfNeeded];
    }];

    // then
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}


- (void)testThatItReregistersPushTokensOnDemand
{
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    // given
    NSData *token = [NSData dataWithBytes:@"abc" length:3];
    NSData *newToken = [NSData dataWithBytes:@"def" length:6];

    [self.mockTransportSession resetReceivedRequests];
    // when
    [self.userSession performChanges:^{
        [self.userSession application:self.userSession.application didRegisterForRemoteNotificationsWithDeviceToken:token];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    ZMTransportRequest *request = self.mockTransportSession.receivedRequests.lastObject;
    XCTAssertEqualObjects(request.path, @"/push/tokens");
    
    [self.mockTransportSession resetReceivedRequests];
    
    // expect
    id mockPushRegistrant = [OCMockObject partialMockForObject:self.userSession.pushRegistrant];
    [(ZMPushRegistrant *)[[mockPushRegistrant expect] andReturn:[NSData dataWithBytes:@"sdsdd" length:5]] pushToken];
    id mockApplication = [OCMockObject partialMockForObject:self.userSession.application];
    [[[mockApplication expect] andDo:^(NSInvocation *inv) {
        NOT_USED(inv);
        [self.userSession performChanges:^{
            [self.userSession application:self.userSession.application didRegisterForRemoteNotificationsWithDeviceToken:newToken];
        }];
    }] registerForRemoteNotifications];
    
    // when
    [self.userSession resetPushTokens];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    BOOL didContainVOIPRequest = NO;
    BOOL didContainRemoteRequest = NO;
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 2u);
    for (ZMTransportRequest *aRequest in self.mockTransportSession.receivedRequests) {
        if (![aRequest.path isEqualToString: @"/push/tokens"]) {
            return;
        }
        NSString *transportType = aRequest.payload[@"transport"];
        if ([transportType isEqualToString:@"APNS_VOIP"]) {
            didContainVOIPRequest = YES;
        }
        if ([transportType isEqualToString:@"APNS"]) {
            didContainRemoteRequest = YES;
        }
    }
    XCTAssertTrue(didContainRemoteRequest);
    XCTAssertTrue(didContainVOIPRequest);

    [mockPushRegistrant verify];
    [mockApplication verify];
}

- (void)testThatItReregistersPushTokensOnDemandEvenIfItDidNotChange
{
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    // given
    NSData *token = [NSData dataWithBytes:@"abc" length:3];
    [self.userSession performChanges:^{
        [self.userSession application:self.userSession.application didRegisterForRemoteNotificationsWithDeviceToken:token];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    [self.mockTransportSession resetReceivedRequests];
    
    // expect
    id mockPushRegistrant = [OCMockObject partialMockForObject:self.userSession.pushRegistrant];
    [(ZMPushRegistrant *)[[mockPushRegistrant expect] andReturn:token] pushToken];
    id mockApplication = [OCMockObject partialMockForObject:self.userSession.application];
    [[[mockApplication expect] andDo:^(NSInvocation *inv) {
        NOT_USED(inv);
        [self.userSession performChanges:^{
            [self.userSession application:self.userSession.application didRegisterForRemoteNotificationsWithDeviceToken:token];
        }];
    }] registerForRemoteNotifications];
    
    // when
    [self.userSession resetPushTokens];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    BOOL didContainVOIPRequest = NO;
    BOOL didContainRemoteRequest = NO;
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 2u);
    for (ZMTransportRequest *aRequest in self.mockTransportSession.receivedRequests) {
        if (![aRequest.path isEqualToString: @"/push/tokens"]) {
            return;
        }
        NSString *transportType = aRequest.payload[@"transport"];
        if ([transportType isEqualToString:@"APNS_VOIP"]) {
            didContainVOIPRequest = YES;
        }
        if ([transportType isEqualToString:@"APNS"]) {
            didContainRemoteRequest = YES;
        }
    }
    XCTAssertTrue(didContainRemoteRequest);
    XCTAssertTrue(didContainVOIPRequest);
    
    [mockPushRegistrant verify];
    [mockApplication verify];
}

- (void)testThatItPingsBackToTheBackendWhenReceivingAVoIPNotificationToCancelTheAPNSNotification
{
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.2);
    
    [self.mockTransportSession closePushChannelAndRemoveConsumer]; // do not use websocket
    
    NSUUID *identifier = NSUUID.createUUID;
    __block NSDictionary *conversationTransportData;

    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        MockConversation *conversation = [session insertGroupConversationWithSelfUser:self.selfUser otherUsers:@[self.user1]];
        conversationTransportData = (NSDictionary *)conversation.transportData;
    }];
    WaitForAllGroupsToBeEmpty(0.2);
    
    NSDictionary *payload = @{
                              @"conversation" : NSUUID.createUUID,
                              @"data" : conversationTransportData,
                              @"from" : self.user1.identifier,
                              @"time" : @"2015-03-11T09:34:00.436Z",
                              @"type" : @"conversation.create"
                              };
    
    // expect
    [[[(id)self.userSession.application stub] andReturnValue:OCMOCK_VALUE(UIApplicationStateBackground)] applicationState];
    
    // when
    [self.mockTransportSession resetReceivedRequests];
    NSDictionary *apnsPayload = [self APNSPayloadForNotificationPayload:payload identifier:identifier];
    [self.userSession receivedPushNotificationWithPayload:apnsPayload completionHandler:nil source:ZMPushNotficationTypeVoIP];
    WaitForAllGroupsToBeEmpty(0.2);
    
    // then
    NSArray <ZMTransportRequest *> *requests = self.mockTransportSession.receivedRequests;
    ZMTransportRequest *lastRequest = requests.lastObject;
    XCTAssertNotNil(lastRequest);
    XCTAssertEqual(lastRequest.method, ZMMethodPOST);
    XCTAssertEqual(requests.count, 1lu);
    
    NSString *expectedPath = [NSString stringWithFormat:@"/push/fallback/%@/cancel", identifier.transportString];
    XCTAssertTrue([lastRequest.path containsString:expectedPath]);
    
}


- (void)testThatItFetchesTheNotificationAndPingsBackToTheBackendWhenReceivingAVoIPNotificationOfTypeNotice
{
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.2);
    
    [self.mockTransportSession closePushChannelAndRemoveConsumer]; // do not use websocket
    ZMUser *selfUser = [self userForMockUser:self.selfUser];
    XCTAssertEqual(selfUser.clients.count, 1u);

    __block NSDictionary *conversationTransportData;
    
    __block NSString *convIdentifier;
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        MockConversation *conversation = [session insertGroupConversationWithSelfUser:self.selfUser otherUsers:@[self.user1]];
        conversationTransportData = (NSDictionary *)conversation.transportData;
        convIdentifier = conversation.identifier;
    }];
    WaitForAllGroupsToBeEmpty(0.2);
    NSUUID *notificationID = NSUUID.createUUID;
    NSUUID *conversationID = [NSUUID uuidWithTransportString:convIdentifier];
    
    NSDictionary *eventPayload = @{@"id" :notificationID.transportString,
                                   @"payload" : @[@{
                                           @"conversation" : convIdentifier,
                                           @"data" : conversationTransportData,
                                           @"from" : self.user1.identifier,
                                           @"time" : @"2015-03-11T09:34:00.436Z",
                                           @"type" : @"conversation.create"
                                           }]
                                   };
    
    NSDictionary *noticePayload = @{@"aps" : @{},
                                    @"data" : @{
                                            @"data" : @{ @"id" : notificationID.transportString },
                                            @"type" : @"notice"
                                            }
                                    };
    
    // expect
    [[[(id)self.userSession.application stub] andReturnValue:OCMOCK_VALUE(UIApplicationStateBackground)] applicationState];
    
    // when
    XCTestExpectation *fetchingExpectation = [self expectationWithDescription:@"fetching notification"];
    XCTestExpectation *pingbackExpectation = [self expectationWithDescription:@"pinging backend"];

    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request) {
        NSString *path = [NSString stringWithFormat:@"/notifications/%@?client=%@", notificationID.transportString,selfUser.selfClient.remoteIdentifier];
        if ([request.path isEqualToString:path] && request.method == ZMMethodGET) {
            [fetchingExpectation fulfill];
            return [ZMTransportResponse responseWithPayload:eventPayload HTTPstatus:200 transportSessionError:nil];
        };
        NSString *fallbackPath = [NSString stringWithFormat:@"/push/fallback/%@/cancel", notificationID.transportString];
        if ([request.path isEqualToString:fallbackPath] && request.method == ZMMethodPOST) {
            [pingbackExpectation fulfill];
        }
        return nil;
    };
    
    [self.mockTransportSession resetReceivedRequests];
    NSDictionary *apnsPayload =  noticePayload;
    [self.userSession receivedPushNotificationWithPayload:apnsPayload completionHandler:nil source:ZMPushNotficationTypeVoIP];
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
    WaitForEverythingToBeDone();
    
    // then
    ZMConversation *conversation = [ZMConversation fetchObjectWithRemoteIdentifier:conversationID inManagedObjectContext:self.uiMOC];
    XCTAssertNotNil(conversation);
}

@end
