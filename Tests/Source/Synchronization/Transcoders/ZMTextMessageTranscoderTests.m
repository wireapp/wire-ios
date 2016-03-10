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


#import "ZMMessageTranscoderTests.h"

#import "ZMMessageTranscoderTests.h"
#import "ZMMessageTranscoder+Internal.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "ZMUser+Internal.h"
#import "ZMConversation+Internal.h"
#import "ZMMessage+Internal.h"
#import "ZMSyncStrategy.h"
#import "ZMUpdateEvent.h"
#import "ZMUpstreamInsertedObjectSync.h"
#import "ZMMessageExpirationTimer.h"
#import "ZMUpstreamTranscoder.h"
#import "ZMChangeTrackerBootstrap+Testing.h"

#import "ZMLocalNotificationDispatcher.h"
#import <zmessaging/ZMUpstreamRequest.h>

@interface ZMTextMessageTranscoderTests : ZMMessageTranscoderTests

@end

@implementation ZMTextMessageTranscoderTests

- (ZMMessageTranscoder *)sut
{
    if (!_sut) {
        _sut = [ZMMessageTranscoder textMessageTranscoderWithManagedObjectContext:self.syncMOC
                                                      localNotificationDispatcher:self.notificationDispatcher];
    }
    return _sut;
}

- (NSDictionary *)postTextMessageResponsePayloadForMessage:(ZMTextMessage *)message eventID:(ZMEventID *)eventID
{
    NSDate *gmtNow = [NSDate date];
    return [self postTextMessageResponsePayloadForMessage:message eventID:eventID serverTime:gmtNow];
}

- (NSDictionary *)postTextMessageResponsePayloadForMessage:(ZMTextMessage *)message eventID:(ZMEventID *)eventID serverTime:(NSDate *)serverTime
{
    
    return @{@"conversation": message.conversation.remoteIdentifier.transportString,
             @"data": @{
                     @"content": @"test test (sorry for the spam)",
                     @"nonce": message.nonce.transportString,
                     },
             @"from": @"90c74fe0-cef7-446a-affb-6cba0e75d5da",
             @"id": eventID.transportString,
             @"time": serverTime.transportString,
             @"type": @"conversation.message-add"
             };
}

#pragma mark - DownloadedMessages

- (void)testThatANewTextMessageIsCreatedFromADownloadedEvent
{
    ZMTextMessage *mockTextMessage = [OCMockObject mockForClass:ZMTextMessage.class];
    ZMUpdateEvent *event = [OCMockObject mockForClass:ZMUpdateEvent.class];
    
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        (void)[(ZMUpdateEvent *)[[(id)event stub] andReturnValue:OCMOCK_VALUE(ZMUpdateEventConversationMessageAdd)] type];
        
        // expect
        [[(id)mockTextMessage expect] createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.syncMOC prefetchResult:nil];
        
        // when
        [self.sut processEvents:@[event] liveEvents:NO prefetchResult:nil];
        
        // then
    }];
    
    [(id)mockTextMessage stopMocking];
    [(id)mockTextMessage verify];
    [(id)event stopMocking];
}

- (void)testThatItDoesNotCreateDownloadedEventTextMessagesFromEventsOfTheWrongType
{
    ZMUpdateEvent *event = [OCMockObject mockForClass:ZMUpdateEvent.class];
    ZMTextMessage *mockTextMessage = [OCMockObject mockForClass:ZMTextMessage.class];

    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        
        // expect
        [[(id)mockTextMessage reject] createOrUpdateMessageFromUpdateEvent:OCMOCK_ANY inManagedObjectContext:self.syncMOC prefetchResult:nil];
        
        
        ZMUpdateEventType ignoredEvents[] = {
            ZMUpdateEventUnknown,
            
            // ZMUpdateEventConversationMessageAdd,
            ZMUpdateEventConversationKnock,
            ZMUpdateEventConversationAssetAdd,
            ZMUpdateEventConversationMemberJoin,
            ZMUpdateEventConversationMemberLeave,
            ZMUpdateEventConversationRename,
            ZMUpdateEventConversationMemberUpdate,
            ZMUpdateEventConversationVoiceChannelActivate,
            ZMUpdateEventConversationVoiceChannel,
            ZMUpdateEventConversationCreate,
            ZMUpdateEventConversationConnectRequest,
            ZMUpdateEventUserUpdate,
            ZMUpdateEventUserNew,
            ZMUpdateEventUserConnection
        };
        
        for (size_t i = 0; i < (sizeof(ignoredEvents) / sizeof(ZMUpdateEventType)); ++i) {
            (void)[(ZMUpdateEvent *)[[(id)event stub] andReturnValue:OCMOCK_VALUE(ignoredEvents[i])] type];
            (void)[(ZMUpdateEvent *)[[(id)event stub] andReturn:@{
                                                                  @"conversation" : [NSUUID createUUID],
                                                                  @"id" : [self createEventID],
                                                                  @"time" : [NSDate dateWithTimeIntervalSince1970:1234000].transportString,
                                                                  @"from" : [NSUUID createUUID],
                                                                  @"data" : @{}
                                                                  }] payload];
            // when
            [self.sut processEvents:@[event] liveEvents:NO prefetchResult:nil];
        }
        
        // then
        
    }];
    
    [(id)mockTextMessage stopMocking];
    [(id)mockTextMessage verify];
    [(id)event stopMocking];
}


#pragma mark - PushEvents


- (void)testThatANewTextMessageIsCreatedFromAPushEvent
{
    ZMTextMessage *mockTextMessage = [OCMockObject mockForClass:ZMTextMessage.class];
    ZMUpdateEvent *event = [OCMockObject mockForClass:ZMUpdateEvent.class];
    
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        (void)[(ZMUpdateEvent *)[[(id)event stub] andReturnValue:OCMOCK_VALUE(ZMUpdateEventConversationMessageAdd)] type];
        
        // expect
        [[(id)mockTextMessage expect] createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.syncMOC prefetchResult:nil];
        
        // when
        [self.sut processEvents:@[event] liveEvents:YES prefetchResult:nil];
        
        // then
    }];
    
    [(id)mockTextMessage stopMocking];
    [(id)mockTextMessage verify];
    [(id)event stopMocking];
}

- (void)testThatItReturnsNoncesForTextMessageFromTheUpdateEventsForPrefetching
{
    // given
    NSMutableSet *expectedNonces = [NSMutableSet set];
    NSMutableArray *events = [NSMutableArray array];
    
    for (ZMUpdateEventType type = 1; type < ZMUpdateEvent_LAST; type++) {
        NSString *eventTypeString = [ZMUpdateEvent eventTypeStringForUpdateEventType:type];
        NSUUID *nonce = NSUUID.createUUID;
        NSDictionary *payload = @{
                                  @"conversation" : NSUUID.createUUID.transportString,
                                  @"id" : self.createEventID.transportString,
                                  @"time" : [NSDate dateWithTimeIntervalSince1970:1234000].transportString,
                                  @"from" : NSUUID.createUUID.transportString,
                                  @"type" : eventTypeString,
                                  @"data" : @{
                                          @"content":@"fooo",
                                          @"nonce" : nonce.transportString,
                                          }
                                  };
        
        ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
        [events addObject:event];
        
        if (type == ZMUpdateEventConversationMessageAdd) {
            [expectedNonces addObject:nonce];
        }
    }
    
    // when
    NSSet <NSUUID *>* actualNonces = [self.sut messageNoncesToPrefetchToProcessEvents:events];
    
    // then
    XCTAssertNotNil(expectedNonces);
    XCTAssertEqual(actualNonces.count, 1lu);
    XCTAssertEqualObjects(expectedNonces, actualNonces);
}

- (void)testThatItDoesNotCreateTextMessagesFromEventsOfTheWrongType
{
    // given
    ZMTextMessage *mockTextMessage = [OCMockObject mockForClass:ZMTextMessage.class];
    ZMUpdateEvent *event = [OCMockObject mockForClass:ZMUpdateEvent.class];

    [self.syncMOC performGroupedBlockAndWait:^{
        
        // expect
        [[(id)mockTextMessage reject] createOrUpdateMessageFromUpdateEvent:OCMOCK_ANY inManagedObjectContext:self.syncMOC prefetchResult:nil];
        
        
        ZMUpdateEventType ignoredEvents[] = {
            ZMUpdateEventUnknown,
            
            // ZMUpdateEventConversationMessageAdd,
            ZMUpdateEventConversationKnock,
            ZMUpdateEventConversationAssetAdd,
            ZMUpdateEventConversationMemberJoin,
            ZMUpdateEventConversationMemberLeave,
            ZMUpdateEventConversationRename,
            ZMUpdateEventConversationMemberUpdate,
            ZMUpdateEventConversationVoiceChannelActivate,
            ZMUpdateEventConversationVoiceChannel,
            ZMUpdateEventConversationCreate,
            ZMUpdateEventConversationConnectRequest,
            ZMUpdateEventUserUpdate,
            ZMUpdateEventUserNew,
            ZMUpdateEventUserConnection
        };
        
        for (size_t i = 0; i < (sizeof(ignoredEvents) / sizeof(ZMUpdateEventType)); ++i) {
            (void)[(ZMUpdateEvent *)[[(id)event stub] andReturnValue:OCMOCK_VALUE(ignoredEvents[i])] type];
            (void)[(ZMUpdateEvent *)[[(id)event stub] andReturn:@{
                                                                  @"conversation" : [NSUUID createUUID],
                                                                  @"id" : [self createEventID],
                                                                  @"time" : [NSDate dateWithTimeIntervalSince1970:1234000].transportString,
                                                                  @"from" : [NSUUID createUUID],
                                                                  @"data" : @{}
                                                                  }] payload];
            // when
            [self.sut processEvents:@[event] liveEvents:YES prefetchResult:nil];
        }
        
    }];
    
    // then
    [(id)mockTextMessage stopMocking];
    [(id)mockTextMessage verify];
    [(id)event stopMocking];
}

- (void)testThatItDoesNotUnarchiveASilencedConversationWhenReceivingAnUpdateEvent
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSUUID *convID = [NSUUID createUUID];
        NSDictionary *payload = @{
                                  @"conversation" : convID.transportString,
                                  @"id" : [self createEventID].transportString,
                                  @"time" : [NSDate dateWithTimeIntervalSince1970:1234000].transportString,
                                  @"from" : [NSUUID createUUID].transportString,
                                  @"type" : @"conversation.message-add",
                                  @"data" : @{
                                          @"content":@"fooo",
                                          @"nonce" : [NSUUID createUUID].transportString,
                                          }
                                  };
        
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.remoteIdentifier = convID;
        conversation.isArchived = YES;
        conversation.isSilenced = YES;
        
        ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
        
        // when
        [self.sut processEvents:@[event] liveEvents:YES prefetchResult:nil];
        
        // then
        XCTAssertTrue(conversation.isArchived);
        
    }];
    
}

@end
