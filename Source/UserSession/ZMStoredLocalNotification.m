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


@import ZMTransport;

#import "ZMStoredLocalNotification.h"
#import "ZMConversation+Internal.h"
#import "ZMUpdateEvent.h"
#import "ZMMessage+Internal.h"
#import "ZMLocalNotification.h"
#import "ZMUserSession+UserNotificationCategories.h"
#import "ZMOperationLoop+Background.h"
#import <zmessaging/zmessaging-Swift.h>

@implementation ZMStoredLocalNotification

- (instancetype)initWithNotification:(UILocalNotification *)notification
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext
                    actionIdentifier:(NSString *)identifier
                           textInput:(NSString*)textInput;
{
    ZMConversation *conversation = [ZMLocalNotification conversationForLocalNotification:notification inManagedObjectContext:managedObjectContext];
    ZMMessage *message;
    if (conversation != nil) {
        message= [ZMLocalNotification messageForLocalNotification:notification conversation:conversation inManagedObjectContext:managedObjectContext];
    }
    
    NSUUID *senderUUID = [ZMLocalNotification senderRemoteIdentifierForLocalNotification:notification];
    
    return [self initWithConversation:conversation
                              message:message
                           senderUUID:senderUUID
                             category:notification.category
                     actionIdentifier:identifier
                            textInput:textInput];
}

- (instancetype)initWithPushPayload:(NSDictionary *)userInfo
               managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    
    ZMStoredLocalNotification *note;
    
    if(userInfo[@"aps"] != nil) {
        NSDictionary *apsDict = [userInfo optionalDictionaryForKey:@"aps"];
        note = [self createStoredLocalNotificationsFromAPNSDictionary:apsDict managedObjectContext:managedObjectContext];
    }
                
    if (note == nil) {
        NSDictionary *payloadData = [userInfo optionalDictionaryForKey:@"data"];
        note = [self createStoredLocalNotificationsFromDataDictionary:payloadData managedObjectContext:managedObjectContext];
    }
    
    return note;
}

- (instancetype)createStoredLocalNotificationsFromAPNSDictionary:(NSDictionary *)apsDictionary managedObjectContext:(NSManagedObjectContext *)context
{
    if (apsDictionary.count == 0) {
        return nil;
    }
    
    NSUUID *conversationID = [apsDictionary optionalUuidForKey:@"conversation_id"];
    if (conversationID == nil) {
        return nil;
    }
    
    ZMConversation *conversation = [ZMConversation conversationWithRemoteID:conversationID createIfNeeded:NO inContext:context];
    
    NSString *eventType = [apsDictionary optionalStringForKey:@"msg_type"];
    ZMUpdateEventType type = [ZMUpdateEvent updateEventTypeForEventTypeString:eventType];
    NSString *category = type == ZMUpdateEventCallState ? ZMCallCategory : ZMConversationCategory;
    return [self initWithConversation:conversation message:nil senderUUID:nil category:category actionIdentifier:nil textInput:nil];
}


- (instancetype)createStoredLocalNotificationsFromDataDictionary:(NSDictionary *)dataDictionary managedObjectContext:(NSManagedObjectContext *)context
{
    if (dataDictionary.count == 0) {
        return nil;
    }
    
    NSDictionary *internalData = [dataDictionary optionalDictionaryForKey:@"data"];
    if (internalData.count != 0) {
        dataDictionary = internalData;
    }
    
    ZMUpdateEvent *event = [[ZMUpdateEvent eventsArrayFromPushChannelData:(id<ZMTransportData>)dataDictionary] firstObject];
    if (event == nil) {
        return nil;
    }
    
    ZMConversation *conversation;
    ZMMessage *message;
    
    NSString *category = (event.type == ZMUpdateEventUserConnection) ? ZMConnectCategory : ZMConversationCategory;
    NSUUID *senderUUID = [event senderUUID];
    
    NSUUID *conversationID = [event conversationUUID];
    if (conversationID != nil) {
        conversation = [ZMConversation conversationWithRemoteID:conversationID createIfNeeded:NO inContext:context];
        NSUUID *messageNonce = [event messageNonce];
        if (messageNonce != nil) {
            message = [ZMMessage fetchMessageWithNonce:messageNonce forConversation:conversation inManagedObjectContext:context];
        }
    }
    
    return [self initWithConversation:conversation message:message senderUUID:senderUUID category:category actionIdentifier:nil textInput:nil];
}

- (instancetype)initWithConversation:(ZMConversation *)conversation
                             message:(ZMMessage *)message
                          senderUUID:(NSUUID *)senderUUID
                            category:(NSString *)category
                    actionIdentifier:(NSString *)identifier
                           textInput:(NSString*)textInput;
{
    self = [super init];
    if (self != nil) {
        _conversation = conversation;
        _message = message;
        _senderUUID = senderUUID;
        _category = category;
        _actionIdentifier = identifier;
        _textInput = textInput;
    }
    return self;
    
}


@end

