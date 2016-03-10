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


@import ZMTransport;
@import ZMUtilities;

#import "CBCryptoBox+UpdateEvents.h"
#import "ZMUser.h"
#import "ZMUpdateEvent.h"
#import <zmessaging/zmessaging-Swift.h>


NSString * CBErrorCodeToString(CBErrorCode errorCode);

@implementation CBCryptoBox (UpdateEvents)

- (BOOL)isEvent:(ZMUpdateEvent *)event forSelfClient:(UserClient *)selfClient
{
    NSString *recipient = [[event.payload.asDictionary optionalDictionaryForKey:@"data"] optionalStringForKey:@"recipient"];
    return recipient != nil && [recipient isEqualToString:selfClient.remoteIdentifier];
}

- (ZMUpdateEvent *)decryptUpdateEventAndAddClient:(ZMUpdateEvent *)event managedObjectContext:(NSManagedObjectContext *)moc
{
    VerifyReturnNil(event != nil);
    
    // check if decrypted already
    ZMUpdateEvent *decryptedEvent;
    if (event.wasDecrypted) {
        return event;
    }
    
    // is it for the current client?
    ZMUser *selfUser = [ZMUser selfUserInContext:moc];
    BOOL checkRecipient = event.type == ZMUpdateEventConversationOtrMessageAdd || event.type == ZMUpdateEventConversationOtrAssetAdd;
    if(checkRecipient && ![self isEvent:event forSelfClient:selfUser.selfClient]) {
        return nil;
    }
    
    // decrypt
    NSString *newSessionId;
    NSError *error = nil;
    if (event.type == ZMUpdateEventConversationOtrMessageAdd) {
        decryptedEvent = [self decryptOTRClientMessageUpdateEvent:event newSessionId:&newSessionId error:&error];
    } else if (event.type == ZMUpdateEventConversationOtrAssetAdd) {
        decryptedEvent = [self decryptOTRAssetUpdateEvent:event newSessionId:&newSessionId error:&error];
    } else {
        return event;
    }
    
    // new client discovered?
    if (newSessionId != nil) {
        NSUUID *userID = [event.payload.asDictionary optionalUuidForKey:@"from"];
        [self didDiscoverNewClientWithSessionId:newSessionId senderId:userID moc:moc];
    }
    
    // failure?
    if (decryptedEvent == nil) {
        [self appendFailedToDecryptMessageForEvent:event error:error managedObjectContext:moc];
    }
    [decryptedEvent appendDebugInformation:event.debugInformation];
    return decryptedEvent;
}

/// Appends a system message for a failed decryption
- (void)appendFailedToDecryptMessageForEvent:(ZMUpdateEvent *)event
                                       error:(NSError *)error
                        managedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    BOOL didFailBecauseDuplicated = error != nil
        && (error.code == CBErrorCodeOutdatedMessage || error.code == CBErrorCodeDuplicateMessage);
    
    // do not notify user if it's just a duplicated one
    if(didFailBecauseDuplicated) {
        return;
    }
    ZMLogError(@"Unable to decrypt event %@, decryption error: %@", event, error);
    [[NSNotificationCenter defaultCenter] postNotificationName:ZMConversationFailedToDecryptMessageNotificationName object:self userInfo:@{@"cause" : CBErrorCodeToString(error.code)}];
    
    NSString *senderClientID = [[event.payload.asDictionary optionalDictionaryForKey:@"data"] optionalStringForKey:@"sender"];
    
    if (event.conversationUUID != nil && event.senderUUID != nil && senderClientID != nil) {
        ZMConversation *conversation = [ZMConversation conversationWithRemoteID:event.conversationUUID createIfNeeded:NO inContext:managedObjectContext];
        ZMUser *sender = [ZMUser userWithRemoteID:event.senderUUID createIfNeeded:NO inContext:managedObjectContext];
        UserClient *client = [UserClient fetchUserClientWithRemoteId:senderClientID forUser:sender createIfNeeded:NO];
        
        if (conversation != nil && sender != nil && client != nil) {
            [conversation appendDecryptionFailedSystemMessageAtTime:event.timeStamp sender:sender client:client];
        }
    }
}

- (ZMUpdateEvent *)decryptOTRClientMessageUpdateEvent:(ZMUpdateEvent *)event newSessionId:(NSString *__autoreleasing *)newSessionId error:(NSError **)error
{
    NSData *decryptedData = [self decryptOTRMessageUpdateEvent:event valueForKey:@"text" newSessionId:newSessionId error:error];
    if (decryptedData == nil) {
        ZMLogError(@"Update Event: %@ failed with error: %@", event.debugInformation, *error);
        
    }
    VerifyReturnNil(decryptedData != nil);

    NSMutableDictionary *payload = [event.payload.asDictionary mutableCopy];
    payload[@"data"] = decryptedData.base64String;

    return [ZMUpdateEvent decryptedUpdateEventFromEventStreamPayload:payload uuid:event.uuid source:event.source];
}

- (ZMUpdateEvent *)decryptOTRAssetUpdateEvent:(ZMUpdateEvent *)event newSessionId:(NSString *__autoreleasing *)newSessionId error:(NSError **)error
{
    NSData *decryptedData = [self decryptOTRMessageUpdateEvent:event valueForKey:@"key" newSessionId:newSessionId error:error];
    if (decryptedData == nil) {
        ZMLogError(@"Update Event: %@ failed with error: %@", event.debugInformation, *error);
        
    }
    VerifyReturnNil(decryptedData != nil);

    NSMutableDictionary *payload = [event.payload.asDictionary mutableCopy];
    NSMutableDictionary *eventData = [[event.payload.asDictionary optionalDictionaryForKey:@"data"] mutableCopy];
    eventData[@"info"] = [decryptedData base64EncodedStringWithOptions:0];
    payload[@"data"] = eventData;

    return [ZMUpdateEvent decryptedUpdateEventFromEventStreamPayload:payload uuid:event.uuid source:event.source];
}

- (NSData *)decryptOTRMessageUpdateEvent:(ZMUpdateEvent *)event valueForKey:(NSString *)dataKey newSessionId:(NSString *__autoreleasing *)newSessionId error:(NSError **)error
{
    NSDictionary *eventData = [event.payload.asDictionary optionalDictionaryForKey:@"data"];
    NSString *senderClientId = [eventData optionalStringForKey:@"sender"];
    NSString *dataString = [eventData optionalStringForKey:dataKey];
    VerifyReturnNil(dataString != nil);
    
    NSData *data = [[NSData alloc] initWithBase64EncodedString:dataString options:0];
    
    VerifyReturnNil(senderClientId != nil);
    VerifyReturnNil(data != nil);
    
    NSData *decryptedData;
    BOOL createdNewSession = [self decryptedMessageDataFromData:data sessionId:senderClientId decryptedData:&decryptedData error:error];
    if (createdNewSession) {
        *newSessionId = senderClientId;
    }
    
    return decryptedData;
}

- (BOOL)decryptedMessageDataFromData:(NSData *)data sessionId:(NSString *)sessionId decryptedData:(NSData **)decryptedData error:(NSError **)error
{
    BOOL createdNewSession;
    
    //If we already have session with sender then we use it to decrypt message
    CBSession *session = [self sessionById:sessionId error:error];
    if (session != nil) {
        *decryptedData = [session decrypt:data error:error];
        if(decryptedData == nil) {
            ZMLogWarn(@"Failed to decrypt message: %@", *error);
        }
        createdNewSession = NO;
    }
    else {
        //if we don't have session with sender yet we create it
        CBSessionMessage *sessionMessage = [self sessionMessageWithId:sessionId fromMessage:data error:error];

        if(sessionMessage == nil || sessionMessage.session == nil) {
            ZMLogWarn(@"Failed to decrypt message: %@", *error);
        }
        
        VerifyReturnValue(sessionMessage != nil, NO);
        VerifyReturnValue(sessionMessage.session != nil, NO);
        
        *decryptedData = sessionMessage.data;
        createdNewSession = YES;
        session = sessionMessage.session;
    }
    [self setSessionToRequireSave:session];
    
    return createdNewSession;
}

- (UserClient *)didDiscoverNewClientWithSessionId:(NSString *)sessionId senderId:(NSUUID *)senderUserId moc:(NSManagedObjectContext *)moc {
    
    if (sessionId != nil && senderUserId != nil) {
        ZMUser *selfUser = [ZMUser selfUserInContext:moc];
        [selfUser.selfClient decrementNumberOfRemainingKeys];
        
        //create user+client and do not trust it
        //user probably will be already created due to preceding member-join event
        //but client will be created only when message from this client is received
        ZMUser *user = [ZMUser userWithRemoteID:senderUserId createIfNeeded:YES inContext:moc];
        if (user != nil) {
            UserClient *newClient = [UserClient fetchUserClientWithRemoteId:sessionId forUser:user createIfNeeded:YES];
            [selfUser.selfClient addNewClientsToIgnored:[NSSet setWithObject:newClient] causedBy:nil];
            return newClient;
        }
    }
    return nil;
}

@end

NSString *
CBErrorCodeToString(CBErrorCode errorCode)
{
    switch (errorCode) {
        case CBErrorCodeUndefined:
            return @"CBErrorCodeUndefined";
        case CBErrorCodeStorageError:
            return @"CBErrorCodeStorageError";
        case CBErrorCodeNoSession:
            return @"CBErrorCodeNoSession";
        case CBErrorCodeNoPreKey:
            return @"CBErrorCodeNoPreKey";
        case CBErrorCodeDecodeError:
            return @"CBErrorCodeDecodeError";
        case CBErrorCodeRemoteIdentityChanged:
            return @"CBErrorCodeRemoteIdentityChanged";
        case CBErrorCodeInvalidIdentity:
            return @"CBErrorCodeInvalidIdentity";
        case CBErrorCodeInvalidSignature:
            return @"CBErrorCodeInvalidSignature";
        case CBErrorCodeInvalidMessage:
            return @"CBErrorCodeInvalidMessage";
        case CBErrorCodeDuplicateMessage:
            return @"CBErrorCodeDuplicateMessage";
        case CBErrorCodeTooDistantFuture:
            return @"CBErrorCodeTooDistantFuture";
        case CBErrorCodeOutdatedMessage:
            return @"CBErrorCodeOutdatedMessage";
        case CBErrorCodeUTF8Error:
            return @"CBErrorCodeUTF8Error";
        case CBErrorCodeNULError:
            return @"CBErrorCodeNULError";
        case CBErrorCodeEncodeError:
            return @"CBErrorCodeEncodeError";
        case CBErrorCodePanic:
            return @"CBErrorCodePanic";
    }

}
