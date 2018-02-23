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


@import WireTesting;
#import "ZMBaseManagedObjectTest.h"
#import "ZMUpdateEvent+WireDataModel.h"
#import "ZMConversation+Internal.h"
#import "ZMUser+Internal.h"

@interface ZMUpdateEventTests : ZMBaseManagedObjectTest

@end

@implementation ZMUpdateEventTests

- (NSDictionary *)typesMapping
{
    return @{
             @"conversation.asset-add" : @(ZMUpdateEventTypeConversationAssetAdd),
             @"conversation.connect-request" : @(ZMUpdateEventTypeConversationConnectRequest),
             @"conversation.create" : @(ZMUpdateEventTypeConversationCreate),
             @"conversation.knock" : @(ZMUpdateEventTypeConversationKnock),
             @"conversation.member-join" : @(ZMUpdateEventTypeConversationMemberJoin),
             @"conversation.member-leave" : @(ZMUpdateEventTypeConversationMemberLeave),
             @"conversation.member-update" : @(ZMUpdateEventTypeConversationMemberUpdate),
             @"conversation.message-add" : @(ZMUpdateEventTypeConversationMessageAdd),
             @"conversation.client-message-add" : @(ZMUpdateEventTypeConversationClientMessageAdd),
             @"conversation.otr-message-add" : @(ZMUpdateEventTypeConversationOtrMessageAdd),
             @"conversation.otr-asset-add" : @(ZMUpdateEventTypeConversationOtrAssetAdd),
             @"conversation.rename" : @(ZMUpdateEventTypeConversationRename),
             @"conversation.typing" : @(ZMUpdateEventTypeConversationTyping),
             @"user.connection" : @(ZMUpdateEventTypeUserConnection),
             @"user.new" : @(ZMUpdateEventTypeUserNew),
             @"user.push-remove" : @(ZMUpdateEventTypeUserPushRemove),
             @"user.update" : @(ZMUpdateEventTypeUserUpdate),
             @"user.contact-join" : @(ZMUpdateEventTypeUserContactJoin),
             @"user.client-add" : @(ZMUpdateEventTypeUserClientAdd),
             @"user.client-remove" : @(ZMUpdateEventTypeUserClientRemove),
             };
}

- (NSArray *)allEventsForConversation:(ZMConversation *)conversation withPayloadData:(NSDictionary *)data
{
    NSDictionary *typesMap = [self typesMapping];
    
    NSMutableArray *events = [NSMutableArray array];
    for (NSString *eventKey in typesMap) {
        ZMUpdateEvent *event = [self eventWithType:eventKey conversation:conversation payloadData:data];
        [events addObject:event];
    }
    return events;
}

- (ZMUpdateEvent *)eventWithType:(NSString *)type conversation:(ZMConversation *)conversation payloadData:(NSDictionary *)data
{
    return [self eventWithType:type conversation:conversation payloadData:data time:nil];
}

- (ZMUpdateEvent *)eventWithType:(NSString *)type conversation:(ZMConversation *)conversation payloadData:(NSDictionary *)data time:(NSDate *)time
{
    NSDictionary *payload = @{@"conversation" : conversation.remoteIdentifier.transportString,
                              @"time" : time ? time.transportString : @"2014-06-18T12:36:51.755Z",
                              @"data" : data ?: @{},
                              @"from" : @"f76c1c7a-7278-4b70-9df7-eca7980f3a5d",
                              @"id" : @"8.800122000a68ee1d",
                              @"type": type
                              };
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    return event;
}

- (void)testThatItCanUnarchiveConversation:(ZMConversation *)conversation withEvent:(ZMUpdateEvent *)event
{
    // when
    BOOL canUnarchive = [event canUnarchiveConversation:conversation];
    
    // then
    switch (event.type) {
        case ZMUpdateEventTypeConversationMemberLeave:
        case ZMUpdateEventTypeConversationAssetAdd:
        case ZMUpdateEventTypeConversationKnock:
        case ZMUpdateEventTypeConversationMemberJoin:
        case ZMUpdateEventTypeConversationMessageAdd:
        case ZMUpdateEventTypeConversationClientMessageAdd:
        case ZMUpdateEventTypeConversationOtrMessageAdd:
        case ZMUpdateEventTypeConversationOtrAssetAdd:
            XCTAssertTrue(canUnarchive);
            break;
        default:
            XCTAssertFalse(canUnarchive);
    }
}


- (void)testReturnsYESForMatchingEventType
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.isArchived = YES;
    conversation.remoteIdentifier = NSUUID.createUUID;
    
    NSArray *events = [self allEventsForConversation:conversation withPayloadData:@{}];

    // when
    for (ZMUpdateEvent *event in events) {
        [self testThatItCanUnarchiveConversation:conversation withEvent:event];
    }
}

- (void)testThatItReturns_NO_ForMemberLeaveEventsWithSelfUser
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    conversation.isArchived = YES;

    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    selfUser.remoteIdentifier = NSUUID.createUUID;
    
    NSDictionary *data = @{@"user_ids":@[selfUser.remoteIdentifier.transportString]};
    
    ZMUpdateEvent *event = [self eventWithType:@"conversation.member-leave" conversation:conversation payloadData:data];
    
    // when
    BOOL canUnarchive = [event canUnarchiveConversation:conversation];
    
    // then
    XCTAssertFalse(canUnarchive);
}


- (void)testThatItReturns_NO_ForWrongConversation
{
    // given
    ZMConversation *conversation1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation1.remoteIdentifier = NSUUID.createUUID;
    conversation1.isArchived = YES;

    ZMConversation *conversation2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation2.remoteIdentifier = NSUUID.createUUID;
    conversation2.isArchived = NO;

    ZMUpdateEvent *event = [self eventWithType:@"conversation.message-add" conversation:conversation1 payloadData:@{}];
    
    // when
    BOOL canUnarchive = [event canUnarchiveConversation:conversation2];
    
    // then
    XCTAssertFalse(canUnarchive);
}

- (void)testThatItReturns_NO_ForTimestampsSmallerThanArchiveTimestampOfConversation
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    conversation.lastServerTimeStamp = [NSDate date];
    conversation.isArchived = YES;
    
    // when
    ZMUpdateEvent *event = [self eventWithType:@"conversation.message-add" conversation:conversation payloadData:@{} time:[conversation.lastServerTimeStamp dateByAddingTimeInterval:-10]];
    BOOL canUnarchive = [event canUnarchiveConversation:conversation];
    
    // then
    XCTAssertFalse(canUnarchive);
}

- (void)testThatItReturns_NO_IfTheConversationIsNotArchived
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    conversation.isArchived = NO;
    
    // when
    ZMUpdateEvent *event = [self eventWithType:@"conversation.message-add" conversation:conversation payloadData:@{}];
    BOOL canUnarchive = [event canUnarchiveConversation:conversation];
    
    // then
    XCTAssertFalse(canUnarchive);
}

- (void)testThatItReturns_NO_IfTheConversationIsSilenced
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    conversation.isArchived = YES;
    conversation.isSilenced = YES;
    
    // when
    ZMUpdateEvent *event = [self eventWithType:@"conversation.message-add" conversation:conversation payloadData:@{}];
    BOOL canUnarchive = [event canUnarchiveConversation:conversation];
    
    // then
    XCTAssertFalse(canUnarchive);
}

@end
