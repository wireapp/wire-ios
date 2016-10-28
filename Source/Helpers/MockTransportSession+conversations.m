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


@import ZMTransport;
@import ZMUtilities;
@import CoreData;
@import ZMProtos;
@import ZMCDataModel;

#import "MockTransportSession+internal.h"
#import "MockTransportSession.h"
#import "MockUser.h"
#import "MockUserClient.h"
#import "MockTransportSession+assets.h"
#import "MockTransportSession+OTR.h"
#import "MockFlowManager.h"


static char* const ZMLogTag ZM_UNUSED = "MockTransport";

static NSString * const JoinedString = @"joined";
static NSString * const IdleString = @"idle";

@implementation MockTransportSession (Conversations)

//TODO: filter requests using array of NSPredicates

// handles /conversations
- (ZMTransportResponse *)processConversationsRequest:(TestTransportSessionRequest *)sessionRequest;
{
    // GET /conversations
    if ((sessionRequest.method == ZMMethodGET) && (sessionRequest.pathComponents.count == 0)) {
        return [self processConversationsGetConversationsRequest:sessionRequest];
    }
    // GET /conversations/ids
    else if ((sessionRequest.method == ZMMethodGET) && (sessionRequest.pathComponents.count == 1) && [sessionRequest.pathComponents[0] isEqualToString:@"ids"])
    {
        return [self processIDsRequest:sessionRequest];
    }
    // GET /conversations/<id>
    else if ((sessionRequest.method == ZMMethodGET) && (sessionRequest.pathComponents.count == 1))
    {
        return [self processConversationsGetConversationRequest:sessionRequest];
    }
    // POST /conversations
    else if ((sessionRequest.method == ZMMethodPOST) && (sessionRequest.pathComponents.count == 0))
    {
        return [self processConversationsPostConversationsRequest:sessionRequest];
    }
    // POST /conversations/<id>/client-messages
    else if ((sessionRequest.method == ZMMethodPOST) && (sessionRequest.pathComponents.count == 2) && [sessionRequest.pathComponents[1] isEqualToString:@"client-messages"])
    {
        return [self processAddGenericMessageToConversationWithRequest:sessionRequest];
    }
    // POST /conversations/<id>/otr/messages
    else if ((sessionRequest.method == ZMMethodPOST) && (sessionRequest.pathComponents.count == 3) && [sessionRequest.pathComponents[1] isEqualToString:@"otr"] && [sessionRequest.pathComponents.lastObject isEqual:@"messages"])
    {
        if (sessionRequest.embeddedRequest.binaryData != nil) {
            return [self processAddOTRMessageToConversationWithRequestWithProtobuffData:sessionRequest];
        }
        else {
            return [self processAddOTRMessageToConversationWithRequest:sessionRequest];
        }
    }
    // POST /conversations/<id>/members
    else if ((sessionRequest.method == ZMMethodPOST) && (sessionRequest.pathComponents.count == 2) && [sessionRequest.pathComponents[1] isEqualToString:@"members"])
    {
        return [self processAddMembersToConversationWithRequest:sessionRequest];
    }
    // PUT /conversations/<id>
    else if ((sessionRequest.method == ZMMethodPUT) && (sessionRequest.pathComponents.count == 1))
    {
        return [self processPutConversationWithRequest:sessionRequest];
    }
    // PUT /conversations/<id>/self
    else if ((sessionRequest.method == ZMMethodPUT) && (sessionRequest.pathComponents.count == 2) && ([sessionRequest.pathComponents[1] isEqualToString:@"self"]))
    {
        return [self processPutConversationSelfWithRequest:sessionRequest];
    }
    // DELETE /conversations/<id>/members/<userid>
    else if ((sessionRequest.method == ZMMethodDELETE) && (sessionRequest.pathComponents.count == 3))
    {
        return [self processDeleteConversationMemberWithRequest:sessionRequest];
    }
    // PUT /conversations/<id>/call/state
    else if ((sessionRequest.method == ZMMethodPUT) && (sessionRequest.pathComponents.count == 3) && [sessionRequest.pathComponents[1] isEqualToString:@"call"] &&
             [sessionRequest.pathComponents[2] isEqualToString:@"state"])
    {
        return [self processCallStateChange:sessionRequest];
    }
    // GET /conversations/<id>/call/state
    else if ((sessionRequest.method == ZMMethodGET) && (sessionRequest.pathComponents.count == 3) && [sessionRequest.pathComponents[1] isEqualToString:@"call"] &&
             [sessionRequest.pathComponents[2] isEqualToString:@"state"])
    {
        return [self processCallStateRequest:sessionRequest];
    }
    // GET /conversations/<id>/call
    else if ((sessionRequest.method == ZMMethodGET) && (sessionRequest.pathComponents.count == 2) && [sessionRequest.pathComponents[1] isEqualToString:@"call"])
    {
        return [self processCallRequest:sessionRequest];
    }
    // POST /conversations/<id>/knock
    else if ((sessionRequest.method == ZMMethodPOST) && (sessionRequest.pathComponents.count == 2) && [sessionRequest.pathComponents[1] isEqualToString:@"knock"])
    {
        return [self processKnockRequest:sessionRequest];
    }
    // POST /conversations/<id>/hot-knock
    else if ((sessionRequest.method == ZMMethodPOST) && (sessionRequest.pathComponents.count == 2) && [sessionRequest.pathComponents[1] isEqualToString:@"hot-knock"])
    {
        return [self processHotKnockRequest:sessionRequest];
    }
    // POST /conversations/<id>/typing
    else if ((sessionRequest.method == ZMMethodPOST) && (sessionRequest.pathComponents.count == 2) && [sessionRequest.pathComponents[1] isEqualToString:@"typing"])
    {
        return [self processTypingRequest:sessionRequest];
    }
    // POST /conversations/<id>/assets
    else if ((sessionRequest.method == ZMMethodPOST) && (sessionRequest.pathComponents.count == 2) && [sessionRequest.pathComponents[1] isEqualToString:@"assets"])
    {
        return [self processAssetRequest:sessionRequest];
    }
    // GET /conversations/<id>/assets/<id>
    else if ((sessionRequest.method == ZMMethodGET) && (sessionRequest.pathComponents.count == 3) && [sessionRequest.pathComponents[1] isEqualToString:@"assets"])
    {
        return [self processAssetRequest:sessionRequest];
    }
    // POST /conversations/<id>/otr/assets
    else if ((sessionRequest.method == ZMMethodPOST) && (sessionRequest.pathComponents.count == 3) && [sessionRequest.pathComponents[2] isEqual:@"assets"])
    {
        return [self processAssetRequest:sessionRequest];
    }
    // POST /conversations/<id>/otr/assets/<assetID>
    else if ((sessionRequest.method == ZMMethodPOST) && (sessionRequest.pathComponents.count == 4) && [sessionRequest.pathComponents[2] isEqualToString:@"assets"])
    {
        return [self processAssetRequest:sessionRequest];
    }
    // GET /conversations/<id>/otr/assets/<assetID>
    else if ((sessionRequest.method == ZMMethodGET) && (sessionRequest.pathComponents.count == 4) && [sessionRequest.pathComponents[2] isEqualToString:@"assets"])
    {
        return [self processAssetRequest:sessionRequest];
    }

    return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];

}

// POST /conversations/<id>/client-messages
- (ZMTransportResponse *)processAddGenericMessageToConversationWithRequest:(TestTransportSessionRequest *)sessionRequest;
{
    NSAssert(self.selfUser != nil, @"No self user in mock transport session");
    
    NSString *content = [sessionRequest.payload.asDictionary stringForKey:@"content"];
    ZMGenericMessage *message = [ZMGenericMessage messageWithBase64String:content];
    
    __unused NSUUID *nonce = [NSUUID uuidWithTransportString:message.messageId];
    NSAssert(nonce != nil, @"");
    
    MockConversation *conversation = [self fetchConversationWithIdentifier:sessionRequest.pathComponents[0]];
    MockEvent *event = [conversation insertClientMessageFromUser:self.selfUser data:message.data];
    return [ZMTransportResponse responseWithPayload:[event transportData] HTTPStatus:201 transportSessionError:nil];
}

// POST /conversations/<id>/otr/messages
- (ZMTransportResponse *)processAddOTRMessageToConversationWithRequest:(TestTransportSessionRequest *)sessionRequest;
{
    NSAssert(self.selfUser != nil, @"No self user in mock transport session");
    
    MockConversation *conversation = [self fetchConversationWithIdentifier:sessionRequest.pathComponents[0]];
    NSAssert(conversation, @"No conv found");

    NSDictionary *recipients = [sessionRequest.payload asDictionary][@"recipients"];
    MockUserClient *senderClient = [self otrMessageSender:sessionRequest.payload.asDictionary];
    if (senderClient == nil) {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
    }

    NSString *onlyForUser = sessionRequest.query[@"report_missing"];
    NSDictionary *missedClients = [self missedClients:recipients conversation:conversation sender:senderClient onlyForUserId:onlyForUser];
    NSDictionary *redundantClients = [self redundantClients:recipients conversation:conversation];
    
    NSDictionary *payload = @{@"missing": missedClients, @"redundant": redundantClients, @"time": [NSDate date].transportString};
    
    NSInteger statusCode = 412;
    if (missedClients.count == 0) {
        statusCode = 201;
        [self insertOTRMessageEventsToConversation:conversation requestPayload:sessionRequest.payload.asDictionary createEventBlock:^MockEvent *(MockUserClient *recipient, NSData *messageData) {
            return [conversation insertOTRMessageFromClient:senderClient toClient:recipient data:messageData];
        }];
    }
    
    return [ZMTransportResponse responseWithPayload:payload HTTPStatus:statusCode transportSessionError:nil];
}

- (ZMTransportResponse *)processAddOTRMessageToConversationWithRequestWithProtobuffData:(TestTransportSessionRequest *)sessionRequest;
{
    NSAssert(self.selfUser != nil, @"No self user in mock transport session");
    
    MockConversation *conversation = [self fetchConversationWithIdentifier:sessionRequest.pathComponents[0]];
    NSAssert(conversation, @"No conv found");
    
    ZMNewOtrMessage *otrMetaData = (ZMNewOtrMessage *)[[[ZMNewOtrMessage builder] mergeFromData:sessionRequest.embeddedRequest.binaryData] build];
    if (otrMetaData == nil) {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
    }
    
    MockUserClient *senderClient = [self otrMessageSenderFromClientId:otrMetaData.sender];
    if (senderClient == nil) {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
    }
    
    NSString *onlyForUser = sessionRequest.query[@"report_missing"];
    NSDictionary *missedClients = [self missedClientsFromRecipients:otrMetaData.recipients conversation:conversation sender:senderClient onlyForUserId:onlyForUser];
    NSDictionary *redundantClients = [self redundantClientsFromRecipients:otrMetaData.recipients conversation:conversation];
    
    NSDictionary *payload = @{@"missing": missedClients, @"redundant": redundantClients, @"time": [NSDate date].transportString};
    
    NSInteger statusCode = 412;
    if (missedClients.count == 0) {
        statusCode = 201;
        [self insertOTRMessageEventsToConversation:conversation requestRecipients:otrMetaData.recipients createEventBlock:^MockEvent *(MockUserClient *recipient, NSData *messageData) {
            return [conversation insertOTRMessageFromClient:senderClient toClient:recipient data:messageData];
        }];
    }
    
    return [ZMTransportResponse responseWithPayload:payload HTTPStatus:statusCode transportSessionError:nil];
}

// PUT /conversations/<id>
- (ZMTransportResponse *)processPutConversationWithRequest:(TestTransportSessionRequest *)sessionRequest;
{
    MockConversation *conversation = [self conversationByIdentifier:sessionRequest.pathComponents[0]];
    if (conversation == nil) {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
    }
    
    NSString *newName = [[sessionRequest.payload asDictionary] stringForKey:@"name"];
    
    if(newName == nil) {
        return [ZMTransportResponse responseWithPayload:@{@"error":@"no name in payload"} HTTPStatus:400 transportSessionError:nil];
    }
    
    MockEvent *event = [conversation changeNameByUser:self.selfUser name:newName];
    return [ZMTransportResponse responseWithPayload:event.transportData HTTPStatus:200 transportSessionError:nil];
}


// returns YES if the payload contains "muted" information
- (BOOL)updateConversation:(MockConversation *)conversation isOTRMutedFromPutSelfConversationPayload:(NSDictionary *)payload
{
    NSString *mutedRef = [payload optionalStringForKey:@"otr_muted_ref"];
    if (mutedRef != nil) {
        NSNumber *muted = [payload optionalNumberForKey:@"otr_muted"];
        conversation.otrMuted = ([muted isEqual:@1]);
        conversation.otrMutedRef = mutedRef;
    }
    
    return mutedRef != nil;
}

// returns YES if the payload contains "muted" information
- (BOOL)updateConversation:(MockConversation *)conversation isOTRArchivedFromPutSelfConversationPayload:(NSDictionary *)payload
{
    NSString *archivedRef = [payload optionalStringForKey:@"otr_archived_ref"];
    if (archivedRef != nil) {
        NSNumber *archived = [payload optionalNumberForKey:@"otr_archived"];
        conversation.otrArchived = ([archived isEqual:@1]);
        conversation.otrArchivedRef = archivedRef;
    }
    
    return archivedRef != nil;
}

// PUT /conversations/<id>/self
- (ZMTransportResponse *)processPutConversationSelfWithRequest:(TestTransportSessionRequest *)sessionRequest;
{
    MockConversation *conversation = [self conversationByIdentifier:sessionRequest.pathComponents[0]];
    if (conversation == nil) {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
    }
    
    NSDictionary *payload = [sessionRequest.payload asDictionary];
    
    BOOL hadOTRMuted = [self updateConversation:conversation isOTRMutedFromPutSelfConversationPayload:payload];
    BOOL hadOTRArchived = [self updateConversation:conversation isOTRArchivedFromPutSelfConversationPayload:payload];

    if( !hadOTRArchived && !hadOTRMuted) {
        return [ZMTransportResponse responseWithPayload:@{@"error":@"no useful payload"} HTTPStatus:400 transportSessionError:nil];
    }
    
    return [ZMTransportResponse responseWithPayload:nil HTTPStatus:200 transportSessionError:nil];
}

// GET /conversations
- (ZMTransportResponse *)processConversationsGetConversationsRequest:(TestTransportSessionRequest *)sessionRequest;
{
    NSFetchRequest *request = [MockConversation sortedFetchRequest];
    NSArray *conversations = [self.managedObjectContext executeFetchRequestOrAssert:request];
    NSMutableArray *data = [NSMutableArray array];
    
    if (sessionRequest.query[@"ids"] != nil) {
        
        NSSet *requestedIDs = [NSSet setWithArray:[sessionRequest.query[@"ids"] componentsSeparatedByString:@","]];
        
        for (MockConversation *conversation in conversations) {
            if([requestedIDs containsObject:conversation.identifier]) {
                [data addObject:conversation.transportData];
            }
        }
    }
    else {
        for (MockConversation *conversation in conversations) {
            [data addObject:conversation.transportData];
        }
    }
    
    return [ZMTransportResponse responseWithPayload:@{@"conversations":data} HTTPStatus:200 transportSessionError:nil];

}

// GET /conversations/<id>
- (ZMTransportResponse *)processConversationsGetConversationRequest:(TestTransportSessionRequest *)sessionRequest;
{
    MockConversation *conversation = [self conversationByIdentifier:sessionRequest.pathComponents[0]];
    if (conversation == nil) {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
    }
    
    return [ZMTransportResponse responseWithPayload:conversation.transportData HTTPStatus:200 transportSessionError:nil];
}

// POST /conversations
- (ZMTransportResponse *)processConversationsPostConversationsRequest:(TestTransportSessionRequest *)sessionRequest;
{
    NSArray *participantIDs = sessionRequest.payload[@"users"];
    NSString *name = sessionRequest.payload[@"name"];
    
    NSMutableArray *otherUsers = [NSMutableArray array];
    
    for (NSString *id in participantIDs) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", id];
        NSFetchRequest *fetchRequest = [MockUser sortedFetchRequestWithPredicate:predicate];
        
        NSArray *results = [self.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
        
        if (results.count == 1) {
            MockUser *user = results[0];
            [otherUsers addObject:user];
        }
    }
    
    MockConversation *conversation = [self insertGroupConversationWithSelfUser:self.selfUser otherUsers:otherUsers];
    if(name != nil) {
        [conversation changeNameByUser:self.selfUser name:name];
    }
    return [ZMTransportResponse responseWithPayload:[conversation transportData] HTTPStatus:200 transportSessionError:nil];
}


// DELETE /conversations/<id>/members/<userid>
- (ZMTransportResponse *)processDeleteConversationMemberWithRequest:(TestTransportSessionRequest *)sessionRequest;
{
    MockConversation *conversation = [self fetchConversationWithIdentifier:sessionRequest.pathComponents[0]];
    if (conversation == nil) {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
    }
    
    MockUser *user = [self fetchUserWithIdentifier:sessionRequest.pathComponents[2]];
    MockEvent *event = [conversation removeUsersByUser:self.selfUser removedUser:user];
    
    return [ZMTransportResponse responseWithPayload:event.transportData HTTPStatus:200 transportSessionError:nil];
}


// POST /conversations/<id>/members
- (ZMTransportResponse *)processAddMembersToConversationWithRequest:(TestTransportSessionRequest *)sessionRequest;
{
    MockConversation *conversation = [self fetchConversationWithIdentifier:sessionRequest.pathComponents[0]];
    
    NSArray *addedUserIDs = sessionRequest.payload[@"users"];
    NSMutableArray *addedUsers = [NSMutableArray array];
    MockUser *selfUser = self.selfUser;
    NSAssert(selfUser != nil, @"Self not found");
    
    for (NSString *userID in addedUserIDs) {
        MockUser *user = [self fetchUserWithIdentifier:userID];
        if(user == nil) {
            return [ZMTransportResponse responseWithPayload:@{
                                                              @"code" : @403,
                                                              @"message": @"Unknown user",
                                                              @"label": @""
                                                              } HTTPStatus:403 transportSessionError:nil];
        }
        
        MockConnection *connection = [self fetchConnectionFrom:selfUser to:user];
        if (connection == nil) {
            return [ZMTransportResponse responseWithPayload:@{
                                                              @"code" : @403,
                                                              @"message": @"Requestor is not connected to users invited",
                                                              @"label": @""
                                                              } HTTPStatus:403 transportSessionError:nil];
        }
        [addedUsers addObject:user];
    }
    
    
    MockEvent *event = [conversation addUsersByUser:self.selfUser addedUsers:addedUsers];
    return [ZMTransportResponse responseWithPayload:event.transportData HTTPStatus:200 transportSessionError:nil];
}

- (MockConversation *)conversationByIdentifier:(NSString *)identifier
{
    NSFetchRequest *request = [MockConversation sortedFetchRequestWithPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", identifier]];
    
    NSArray *conversations = [self.managedObjectContext executeFetchRequestOrAssert:request];
    RequireString(conversations.count <= 1, "Too many conversations with one identifier");
    
    return conversations.count > 0 ? conversations[0] : nil;
}

// PUT /conversations/<id>/call/state
- (ZMTransportResponse *)processCallStateChange:(TestTransportSessionRequest *)sessionRequest
{
    NSDictionary *selfState = [sessionRequest.payload asDictionary][@"self"];
    NSString *incomingState = selfState[@"state"];
    
    MockConversation *conversation = [self conversationByIdentifier:sessionRequest.pathComponents[0]];
    
    BOOL isJoining = [incomingState isEqualToString:JoinedString];
    BOOL isSendingVideo = [selfState[@"videod"] boolValue];
    if (isSendingVideo && isJoining) {
        conversation.isVideoCall = YES;
        self.selfUser.isSendingVideo = YES;
    } else {
        self.selfUser.isSendingVideo = NO;
    }
    BOOL isIgnoringCall = [selfState[@"ignored"] boolValue];
    if (isIgnoringCall) {
        self.selfUser.ignoredCallConversation = conversation;
    } else {
        self.selfUser.ignoredCallConversation = nil;
    }

    NSInteger statusCode;
    NSDictionary *payLoad;
    if(conversation == nil) {
        statusCode = 404;
    }
    else if(conversation.type != ZMTConversationTypeOneOnOne && conversation.type != ZMTConversationTypeGroup) {
        statusCode = 400;
    }
    else if ([incomingState isEqualToString:JoinedString] || [incomingState isEqualToString:IdleString]) {
        statusCode = 200;

        BOOL selfWasJoined = [conversation.callParticipants containsObject:self.selfUser];
        BOOL generateSuccessPayload = YES;
        
        if(!isJoining) {
            if (conversation.type == ZMTConversationTypeOneOnOne ) {
                if (selfWasJoined) {
                    [conversation callEndedEventFromUser:self.selfUser selfUser:self.selfUser];
                    [self.mockFlowManager resetVideoCalling];
                    conversation.isVideoCall = NO;
                }
            }
            else {
                [conversation removeUserFromCall:self.selfUser];
                if (conversation.callParticipants.count == 1) {
                    conversation.isVideoCall = NO;
                    [self.mockFlowManager resetVideoCalling];
                }
            }
        }

        if(isJoining) {
            if (conversation.type == ZMTConversationTypeGroup && conversation.callParticipants.count >= self.maxCallParticipants) {
                statusCode = 409;
                payLoad = @{@"label": @"voice-channel-full", @"max_joined": @(self.maxCallParticipants)};
                generateSuccessPayload = NO;
            }
            else if (conversation.type == ZMTConversationTypeGroup && conversation.activeUsers.count >= self.maxMembersForGroupCall) {
                statusCode = 409;
                payLoad = @{@"label": @"conv-too-big", @"max_members": @(self.maxMembersForGroupCall)};
                generateSuccessPayload = NO;
            }
            else {
                [conversation addUserToCall:self.selfUser];
            }
        }
        if (generateSuccessPayload) {
            payLoad = [self combinedCallStateForConversation:conversation];
        }
    }
    else {
        statusCode = 400;
    }
    
    
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:payLoad HTTPStatus:statusCode transportSessionError:nil];
    return response;
}

// GET /conversations/<id>/call/state
- (ZMTransportResponse *)processCallStateRequest:(TestTransportSessionRequest *)sessionRequest
{
    MockConversation *conversation = [self conversationByIdentifier:sessionRequest.pathComponents[0]];
    NOT_USED(sessionRequest);
    
    NSInteger statusCode;
    NSDictionary *payload;
    if (conversation == nil) {
        statusCode = 404;
    }
    else if(conversation.type != ZMTConversationTypeOneOnOne && conversation.type != ZMTConversationTypeGroup) {
        statusCode = 400;
    }
    else {
        statusCode = 200;
        payload = [self combinedCallStateForConversation:conversation];
    }
    
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:payload HTTPStatus:statusCode transportSessionError:nil];
    return response;
}

// GET /conversations/<id>/call
- (ZMTransportResponse *)processCallRequest:(TestTransportSessionRequest *)sessionRequest
{
    MockConversation *conversation = [self conversationByIdentifier:sessionRequest.pathComponents[0]];
    NOT_USED(sessionRequest);
    
    
    NSInteger statusCode;
    NSDictionary *payload;
    if (conversation == nil) {
        statusCode = 404;
    }
    else if(conversation.type != ZMTConversationTypeOneOnOne && conversation.type != ZMTConversationTypeGroup) {
        statusCode = 400;
    }
    else if(conversation.type == ZMTConversationTypeGroup && conversation.activeUsers.count >= self.maxMembersForGroupCall) {
        statusCode = 409;
        payload = @{@"label": @"conv-too-big", @"max_members": @(self.maxMembersForGroupCall)};
    }
    else if(conversation.type == ZMTConversationTypeGroup && conversation.callParticipants.count >= self.maxCallParticipants) {
        statusCode = 409;
        payload = @{@"label": @"voice-channel-full", @"max_joined": @(self.maxCallParticipants)};
    }
    else {
        statusCode = 200;
        payload = [self combinedCallStateForConversation:conversation];
    }
    
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:payload HTTPStatus:statusCode transportSessionError:nil];
    return response;
}

- (NSDictionary *)combinedCallStateForConversation:(MockConversation *)conversation
{
    return @{
             @"participants": [self participantsPayloadForConversation:conversation],
             @"self": [self callStateForUser:self.selfUser conversation:conversation],
             };
}


// POST /conversations/<id>/knock
- (ZMTransportResponse *)processKnockRequest:(TestTransportSessionRequest *)sessionRequest
{
    NSInteger statusCode;
    NSDictionary *payload;
    
    MockConversation *conversation = [self conversationByIdentifier:sessionRequest.pathComponents[0]];
    if (conversation == nil) {
        statusCode = 404;
    }
    else {
        statusCode = 201;
        NSUUID *nonce = [NSUUID uuidWithTransportString:sessionRequest.payload[@"nonce"]];
        MockEvent *event = [conversation insertKnockFromUser:self.selfUser nonce:nonce];
        payload = [event transportData].asDictionary;
    }
    
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:payload HTTPStatus:statusCode transportSessionError:nil];
    return response;
}


// POST /conversations/<id>/hot-knock
- (ZMTransportResponse *)processHotKnockRequest:(TestTransportSessionRequest *)sessionRequest
{
    NSInteger statusCode;
    NSDictionary *payload;
    
    MockConversation *conversation = [self conversationByIdentifier:sessionRequest.pathComponents[0]];
    if (conversation == nil) {
        statusCode = 404;
    }
    else {
        statusCode = 201;
        NSUUID *nonce = [NSUUID uuidWithTransportString:sessionRequest.payload[@"nonce"]];
        MockEvent *event = [conversation insertHotKnockFromUser:self.selfUser nonce:nonce ref:@""];
        payload = [event transportData].asDictionary;
    }
    
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:payload HTTPStatus:statusCode transportSessionError:nil];
    return response;
}

// POST /conversations/<id>/typing
- (ZMTransportResponse *)processTypingRequest:(TestTransportSessionRequest *)sessionRequest
{
    NSInteger statusCode;
    NSDictionary *payload;
    
    MockConversation *conversation = [self conversationByIdentifier:sessionRequest.pathComponents[0]];
    if (conversation == nil) {
        statusCode = 404;
    }
    else {
        statusCode = 201;
        NSDictionary *requestPayload = [sessionRequest.payload asDictionary];
        BOOL isTyping = [[requestPayload optionalStringForKey:@"status"] isEqualToString:@"started"];
        MockEvent *event = [conversation insertTypingEventFromUser:self.selfUser isTyping:isTyping];
        payload = [event transportData].asDictionary;
    }
    
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:payload HTTPStatus:statusCode transportSessionError:nil];
    return response;
}

// GET /conversations/ids
- (ZMTransportResponse *)processIDsRequest:(TestTransportSessionRequest *)sessionRequest
{
    NSString *sizeString = [sessionRequest.query optionalStringForKey:@"size"];
    NSUUID *start = [sessionRequest.query optionalUuidForKey:@"start"];
    
    NSFetchRequest *request = [MockConversation sortedFetchRequest];
    NSArray *conversations = [self.managedObjectContext executeFetchRequestOrAssert:request];

    NSArray *conversationIDs = [conversations mapWithBlock:^id(MockConversation *obj) {
        return obj.identifier;
    }];
    
    if(start != nil) {
        NSUInteger index = [conversationIDs indexOfObject:start.transportString];
        if(index != NSNotFound) {
            conversationIDs = [conversationIDs subarrayWithRange:NSMakeRange(index+1, conversationIDs.count - index-1)];
        }
    }

    BOOL hasMore = NO;
    if(sizeString != nil) {
        NSUInteger remainingConversations = conversationIDs.count;
        NSUInteger pageSize = (NSUInteger) sizeString.integerValue;
        hasMore = (remainingConversations > pageSize);
        NSUInteger numOfConversations = MIN(remainingConversations, pageSize);
        conversationIDs = [conversationIDs subarrayWithRange:NSMakeRange(0u, numOfConversations)];
    }
    
    NSDictionary *payload = @{
                              @"has_more": @(hasMore),
                              @"conversations": conversationIDs
                              };
    
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil];
    return response;
}

- (NSDictionary *)participantsPayloadForConversation:(MockConversation *)conversation
{
    NSMutableDictionary *participantsPayload = [NSMutableDictionary dictionary];
    for(MockUser *user in conversation.activeUsers)
    {
        participantsPayload[user.identifier] = [self callStateForUser:user conversation:conversation];
    }
    
    RequireString(self.selfUser != nil, "No self-user in conversation");
//    RequireString(conversation.callParticipants.count > 0, "No other user in conversation");
    
    return participantsPayload;
}

- (NSDictionary *)callStateForUser:(MockUser*)user conversation:(MockConversation *)conversation
{
    BOOL isJoined = [conversation.callParticipants containsObject:user];
    
    NSString *stateString = isJoined ? JoinedString : IdleString;
    BOOL isSendingVideo = conversation.isVideoCall && user.isSendingVideo;
    NSMutableDictionary *state = [NSMutableDictionary dictionary];
    state[@"state"] = stateString;
    state[@"videod"] = isSendingVideo ? @YES : @NO;
    if (user.ignoredCallConversation != nil) {
        state[@"ignored"] = @YES;
    }
    
    return state;
}

@end
