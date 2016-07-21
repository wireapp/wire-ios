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


#import "ZMMessage+Internal.h"
#import "ZMOTRMessage.h"

@class UserClient;
@protocol ZMConversationMessage;

extern NSString * const ZMFailedToCreateEncryptedMessagePayloadString;
extern NSUInteger const ZMClientMessageByteSizeExternalThreshold;

@interface ZMClientMessage : ZMOTRMessage

@property (nonatomic, readonly) ZMGenericMessage *genericMessage;

- (void)addData:(NSData *)data;

@end

@interface ZMClientMessage (OTR)

- (NSData *)encryptedMessagePayloadData;

+ (NSArray *)recipientsWithDataToEncrypt:(NSData *)dataToEncrypt
                              selfClient:(UserClient *)selfClient
                            conversation:(ZMConversation *)converation;

+ (NSData *)encryptedMessagePayloadDataWithGenericMessage:(ZMGenericMessage *)genericMessage
                                             conversation:(ZMConversation *)conversation
                                     managedObjectContext:(NSManagedObjectContext *)moc
                                             externalData:(NSData *)externalData;

@end

@interface ZMClientMessage (External)

+ (NSData *)encryptedMessageDataWithExternalDataBlobFromMessage:(ZMGenericMessage *)message
                                                 inConversation:(ZMConversation *)conversation
                                           managedObjectContext:(NSManagedObjectContext *)context;

@end
