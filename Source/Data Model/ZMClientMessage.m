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


@import ZMCSystem;
@import ZMUtilities;
@import ZMTransport;
@import ZMProtos;
@import CoreGraphics;
@import ImageIO;
@import MobileCoreServices;

#import "ZMClientMessage.h"
#import "ZMConversation+Internal.h"
#import "ZMGenericMessageData.h"
#import "ZMUser+Internal.h"
#import "ZMOTRMessage.h"
#import "ZMGenericMessage+External.h"
#import <zmessaging/zmessaging-Swift.h>

static NSString * const ClientMessageDataSetKey = @"dataSet";
static NSString * const ClientMessageGenericMessageKey = @"genericMessage";

NSString * const ZMFailedToCreateEncryptedMessagePayloadString = @"💣";
// From https://github.com/wearezeta/generic-message-proto:
// "If payload is smaller then 256KB then OM can be sent directly"
// Just to be sure we set the limit lower, to 128KB (base 10)
NSUInteger const ZMClientMessageByteSizeExternalThreshold = 128000;

@interface ZMClientMessage()

@property (nonatomic) ZMGenericMessage *genericMessage;

@end

@interface ZMClientMessage (ZMKnockMessageData) <ZMKnockMessageData>

@end

@implementation ZMClientMessage

@synthesize genericMessage = _genericMessage;

- (void)awakeFromInsert;
{
    [super awakeFromInsert];
    self.nonce = nil;
}

+ (NSString *)entityName;
{
    return @"ClientMessage";
}

- (void)addData:(NSData *)data
{
    if (data == nil) {
        return;
    }
    
    ZMGenericMessageData *messageData = [NSEntityDescription insertNewObjectForEntityForName:[ZMGenericMessageData entityName] inManagedObjectContext:self.managedObjectContext];
    messageData.data = data;
    messageData.message = self;
    [self setGenericMessage:messageData.genericMessage];
    
    if (self.nonce == nil) {
        self.nonce = [NSUUID uuidWithTransportString:messageData.genericMessage.messageId];
    }
    
    [self setLocallyModifiedKeys:[NSSet setWithObject:ClientMessageDataSetKey]];
}

- (ZMGenericMessage *)genericMessage
{
    if (_genericMessage == nil) {
        _genericMessage = [self genericMessageFromDataSet] ?: (ZMGenericMessage *)[NSNull null];
    }
    if (_genericMessage == (ZMGenericMessage *)[NSNull null]) {
        return nil;
    }
    return _genericMessage;
}

- (void)setGenericMessage:(ZMGenericMessage *)genericMessage
{
    if ([genericMessage knownMessage] && !genericMessage.hasImage) {
        _genericMessage = genericMessage;
    }
}

- (ZMGenericMessage *)genericMessageFromDataSet
{
    // Later we need to loop through data set and merge it in one generic message somehow
    // for now we just pick the first data that can read
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(ZMGenericMessageData *evaluatedObject, NSDictionary *__unused bindings) {
        ZMGenericMessage *genericMessage = evaluatedObject.genericMessage;
        return [genericMessage knownMessage] && !genericMessage.hasImage;
    }];
    ZMGenericMessageData *messageData = [self.dataSet filteredOrderedSetUsingPredicate:predicate].firstObject;
    return [messageData genericMessage];
}

+ (NSSet *)keyPathsForValuesAffectingGenericMessage
{
    return [NSSet setWithObject:ClientMessageDataSetKey];
}

+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext *)moc
                         prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    return [ZMClientMessage createOrUpdateMessageFromUpdateEvent:updateEvent
                                          inManagedObjectContext:moc
                                                     entityClass:ZMClientMessage.class
                                                  prefetchResult:prefetchResult];
}

+ (id)genericMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent entityClass:(Class)entityClass;
{
    ZMGenericMessage *message;
    @try {
        message = [entityClass genericMessageFromUpdateEvent:updateEvent];
    }
    @catch(NSException *e) {
        ZMLogError(@"Cannot create message from protobuffer: %@ event: %@", e, updateEvent);
        return nil;
    }
    VerifyReturnNil(message != nil);
    return message;
}

+ (id)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent inManagedObjectContext:(NSManagedObjectContext *)moc entityClass:(Class)entityClass prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult;
{
    ZMGenericMessage *message;
    @try {
        message = [entityClass genericMessageFromUpdateEvent:updateEvent];
    }
    @catch(NSException *e) {
        ZMLogError(@"Cannot create message from protobuffer: %@", e);
        return nil;
    }
    VerifyReturnNil(message != nil);
    
    BOOL encrypted = [updateEvent isEncrypted];
    
    ZMConversation *conversation = [entityClass conversationForUpdateEvent:updateEvent inContext:moc prefetchResult:prefetchResult];
    VerifyReturnNil(conversation != nil);
    
    if (message.hasLastRead && conversation.conversationType == ZMConversationTypeSelf) {
        [ZMConversation updateConversationWithZMLastReadFromSelfConversation:message.lastRead inContext:moc];
    }
    if (message.hasCleared && conversation.conversationType == ZMConversationTypeSelf) {
        [ZMConversation updateConversationWithZMClearedFromSelfConversation:message.cleared inContext:moc];
    }
    
    if (![conversation shouldAddEvent:updateEvent] || message.hasClientAction) {
        [conversation addEventToDownloadedEvents:updateEvent.eventID timeStamp:updateEvent.timeStamp];
        return nil;
    }
    
    ZMMessage *preExistingPlainMessage = [ZMClientMessage preExistingPlainMessageForGenericMessage:message
                                                                                    inConversation:conversation
                                                                            inManagedObjectContext:moc
                                                                                prefetchResult:prefetchResult];
    if (preExistingPlainMessage != nil) {
        preExistingPlainMessage.isEncrypted = encrypted;
        return nil;
    }

    NSUUID *nonce = [NSUUID uuidWithTransportString:message.messageId];
    
    ZMClientMessage *clientMessage = [entityClass fetchMessageWithNonce:nonce
                                                        forConversation:conversation
                                                 inManagedObjectContext:moc
                                                         prefetchResult:prefetchResult];
    if (clientMessage == nil) {
        clientMessage = [entityClass insertNewObjectInManagedObjectContext:moc];
    }
    
    clientMessage.isEncrypted = encrypted;
    clientMessage.isPlainText = !encrypted;
    clientMessage.nonce = nonce;
    [clientMessage updateWithGenericMessage:message updateEvent:updateEvent];
    [clientMessage updateWithUpdateEvent:updateEvent forConversation:conversation messageWasAlreadyReceived:clientMessage.delivered];

    return clientMessage;
}

+ (ZMGenericMessage *)genericMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
{
    ZMGenericMessage *message;
    if (updateEvent.type == ZMUpdateEventConversationClientMessageAdd ||
        updateEvent.type == ZMUpdateEventConversationOtrMessageAdd)
    {
        NSString *base64Content = [updateEvent.payload stringForKey:@"data"];
        message = [self genericMessageWithBase64String:base64Content updateEvent:updateEvent];
        VerifyReturnNil(message != nil);
    }
    
    if (message.hasExternal) {
        return [self genericMessageFromUpdateEventWithExternal:updateEvent external:message.external];
    }
    
    return message;
}

+ (ZMGenericMessage *)genericMessageWithBase64String:(NSString *)string updateEvent:(ZMUpdateEvent *)event
{
    VerifyReturnNil(nil != string);
    ZMGenericMessage *message;
    @try {
        message = [ZMGenericMessage messageWithBase64String:string];
    } @catch (NSException *exception) {
        ZMLogError(@"Cannot create message from protobuffer: %@ event: %@", exception, event);
        return nil;
    }
    return message;
}

+ (ZMMessage *)preExistingPlainMessageForGenericMessage:(ZMGenericMessage *)message inConversation:(ZMConversation *)conversation inManagedObjectContext:(NSManagedObjectContext *)moc prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    Class messageClass;
    if (message.hasText) {
        messageClass = [ZMTextMessage self];
    }
    else if (message.hasImage) {
        messageClass = [ZMImageMessage self];
    }
    else if (message.hasKnock) {
        messageClass = [ZMKnockMessage self];
    }
    else {
        return nil;
    }
    
    return [messageClass fetchMessageWithNonce:[NSUUID uuidWithTransportString:message.messageId]
                               forConversation:conversation
                        inManagedObjectContext:moc
                                prefetchResult:prefetchResult];
}

- (void)updateWithGenericMessage:(ZMGenericMessage *)message updateEvent:(ZMUpdateEvent *__unused)updateEvent
{
    [self addData:message.data];
}

- (NSString *)messageText
{
    if(self.genericMessage.hasText) {
        return self.genericMessage.text.content;
    }
    return nil;
}

- (id<ZMImageMessageData>)imageMessageData
{
    return nil;
}

- (id<ZMKnockMessageData>)knockMessageData
{
    if (self.genericMessage.hasKnock) {
        return self;
    }
    return nil;
}

- (void)updateWithPostPayload:(NSDictionary *)payload updatedKeys:(__unused NSSet *)updatedKeys
{
    [super updateWithPostPayload:payload updatedKeys:nil];
    
    NSDate *serverTimestamp = [payload dateForKey:@"time"];
    if (serverTimestamp != nil) {
        self.serverTimestamp = serverTimestamp;
    }
    [self.conversation updateLastReadServerTimeStampIfNeededWithTimeStamp:serverTimestamp andSync:YES];
    [self.conversation resortMessagesWithUpdatedMessage:self];
    [self.conversation updateWithMessage:self timeStamp:serverTimestamp eventID:self.eventID];
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeInsertedUpstream
{
    NSPredicate *publicNotSynced = [NSPredicate predicateWithFormat:@"%K == NULL && %K == FALSE", ZMMessageEventIDDataKey, ZMMessageIsEncryptedKey];
    NSPredicate *encryptedNotSynced = [NSPredicate predicateWithFormat:@"%K == TRUE && %K == FALSE", ZMMessageIsEncryptedKey, DeliveredKey];
    NSPredicate *notSynced = [NSCompoundPredicate orPredicateWithSubpredicates:@[publicNotSynced, encryptedNotSynced]];
    NSPredicate *notExpired = [NSPredicate predicateWithFormat:@"%K == 0", ZMMessageIsExpiredKey];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[notSynced, notExpired]];
}

@end



@implementation ZMClientMessage (OTR)

- (NSData *)encryptedMessagePayloadData
{
    return [ZMClientMessage encryptedMessagePayloadDataWithGenericMessage:self.genericMessage
                                                             conversation:self.conversation
                                                     managedObjectContext:self.managedObjectContext
                                                             externalData:nil];
}

+ (NSData *)encryptedMessagePayloadDataWithGenericMessage:(ZMGenericMessage *)genericMessage conversation:(ZMConversation *)conversation managedObjectContext:(NSManagedObjectContext *)moc externalData:(NSData *)externalData
{
    UserClient *selfClient = [ZMUser selfUserInContext:moc].selfClient;
    if (selfClient.remoteIdentifier == nil) {
        return nil;
    }
    
    NSArray <ZMUserEntry *>*recipients = [ZMClientMessage recipientsWithDataToEncrypt:genericMessage.data
                                                                           selfClient:selfClient
                                                                         conversation:conversation];
    ZMNewOtrMessage *message = [ZMNewOtrMessage messageWithSender:selfClient nativePush:YES recipients:recipients blob:externalData];
    
    
    NSData *messageData = message.data;
    if (messageData.length > ZMClientMessageByteSizeExternalThreshold && nil == externalData) {
        return [self encryptedMessageDataWithExternalDataBlobFromMessage:genericMessage
                                                          inConversation:conversation
                                                    managedObjectContext:moc];
    }
    
    return messageData;
}

+ (NSArray <ZMUserEntry *>*)recipientsWithDataToEncrypt:(NSData *)dataToEncrypt selfClient:(UserClient *)selfClient conversation:(ZMConversation *)conversation;
{
    CBCryptoBox *box = selfClient.keysStore.box;
    
    NSArray <ZMUserEntry *>*recipients = [conversation.activeParticipants.array mapWithBlock:^ ZMUserEntry *(ZMUser *user) {
        NSArray <ZMClientEntry *>*clientsEntries = [user.clients.allObjects mapWithBlock:^ZMClientEntry *(UserClient *client) {
            
            NSError *error;
            if (![client.remoteIdentifier isEqual:selfClient.remoteIdentifier]) {
                CBSession *session = [box sessionById:client.remoteIdentifier error:&error];
                
                // We do not have a session and will insert bogus data for this client
                // in order to show him a "failed to decrypt" message
                BOOL corruptedClient = client.failedToEstablishSession;
                client.failedToEstablishSession = NO;
                
                if (nil == session && corruptedClient) {
                    NSData *data = [ZMFailedToCreateEncryptedMessagePayloadString dataUsingEncoding:NSUTF8StringEncoding];
                    return [ZMClientEntry entryWithClient:client data:data];
                }
                
                NSData *encryptedData = [session encrypt:dataToEncrypt error:&error];
                if (encryptedData != nil) {
                    [box setSessionToRequireSave:session];
                    return [ZMClientEntry entryWithClient:client data:encryptedData];
                }
            }

            return nil;
        }];
        
        if (clientsEntries.count == 0) {
            return nil;
        }
        
        return [ZMUserEntry entryWithUser:user clientEntries:clientsEntries];
    }];

    return recipients;
}

@end



@implementation ZMClientMessage (External)

+ (ZMGenericMessage *)genericMessageFromUpdateEventWithExternal:(ZMUpdateEvent *)updateEvent external:(ZMExternal *)external
{
    NSData *sha256 = external.sha256;
    NSData *otrKey = external.otrKey;
    VerifyReturnNil(nil != sha256);
    VerifyReturnNil(nil != otrKey);
    
    NSString *externalDataString = [updateEvent.payload optionalStringForKey:@"external"];
    VerifyReturnNil(nil != externalDataString);
    NSData *externalData = [[NSData alloc] initWithBase64EncodedString:externalDataString options:0];
    NSData *externalSha256 = externalData.zmSHA256Digest;
    
    if (! [externalSha256 isEqualToData:sha256]) {
        ZMLogError(@"Invalid hash for external data: %@ != %@, updateEvent: %@", externalSha256, sha256, updateEvent);
        return nil;
    }
    
    NSData *decryptedData = [externalData zmDecryptPrefixedPlainTextIVWithKey:otrKey];
    VerifyReturnNil(nil != decryptedData);
    
    return [self genericMessageWithBase64String:decryptedData.base64String updateEvent:updateEvent];
}

+ (NSData *)encryptedMessageDataWithExternalDataBlobFromMessage:(ZMGenericMessage *)message
                                                 inConversation:(ZMConversation *)conversation
                                           managedObjectContext:(NSManagedObjectContext *)context
{
    ZMExternalEncryptedDataWithKeys *encryptedDataWithKeys = [ZMGenericMessage encryptedDataWithKeysFromMessage:message];
    ZMGenericMessage *externalGenericMessage = [ZMGenericMessage genericMessageWithKeyWithChecksum:encryptedDataWithKeys.keys
                                                                                         messageID:NSUUID.UUID.transportString];
    
    return [self encryptedMessagePayloadDataWithGenericMessage:externalGenericMessage
                                                  conversation:conversation
                                          managedObjectContext:context
                                                  externalData:encryptedDataWithKeys.data];
}

@end



@implementation ZMClientMessage (ZMKnockMessage)

@end

