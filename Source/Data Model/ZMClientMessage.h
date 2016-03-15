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


#import "ZMMessage+Internal.h"
#import "ZMOTRMessage.h"


@class UserClient;

extern NSString * const ZMFailedToCreateEncryptedMessagePayloadString;


@interface ZMClientMessage : ZMOTRMessage <ZMConversationMessage>

@property (nonatomic, readonly) ZMGenericMessage *genericMessage;

- (void)addData:(NSData *)data;

/// Returns the generic message contained in the given update event
+ (id)genericMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent entityClass:(Class)entityClass;

+ (id)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
                    inManagedObjectContext:(NSManagedObjectContext *)moc
                               entityClass:(Class)entityClass
                       prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult;

+ (ZMMessage *)preExistingPlainMessageForGenericMessage:(ZMGenericMessage *)message
                                         inConversation:(ZMConversation *)conversation
                                 inManagedObjectContext:(NSManagedObjectContext *)moc
                                         prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult;

@end

@interface ZMClientMessage (OTR)

- (NSData *)encryptedMessagePayloadData;
+ (NSArray *)recipientsWithDataToEncrypt:(NSData *)dataToEncrypt selfClient:(UserClient *)selfClient conversation:(ZMConversation *)converation;

@end
