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


@import zimages;
#import "ZMMessage+Internal.h"
#import "ZMOTRMessage.h"

@class UserClient;
@protocol ZMConversationMessage;

extern NSString * _Nonnull const ZMFailedToCreateEncryptedMessagePayloadString;
extern NSUInteger const ZMClientMessageByteSizeExternalThreshold;
extern NSString * _Nonnull const ZMClientMessageLinkPreviewStateKey;
extern NSString * _Nonnull const ZMClientMessageLinkPreviewImageDownloadNotificationName;

@interface ZMClientMessage : ZMOTRMessage

/// Link Preview state
@property (nonatomic) ZMLinkPreviewState linkPreviewState;

@property (nonatomic, readonly) ZMGenericMessage * _Nullable genericMessage;

- (void)addData:(NSData * _Nonnull)data;

- (BOOL)hasDownloadedImage;

@end

@interface ZMClientMessage (OTR)

- (NSData * _Nullable)encryptedMessagePayloadData;

+ (NSArray * _Nullable)recipientsWithDataToEncrypt:(NSData * _Nonnull)dataToEncrypt
                              selfClient:(UserClient * _Nonnull)selfClient
                            conversation:(ZMConversation * _Nonnull)converation;

+ (NSData * _Nullable)encryptedMessagePayloadDataWithGenericMessage:(ZMGenericMessage * _Nonnull)genericMessage
                                             conversation:(ZMConversation * _Nonnull)conversation
                                     managedObjectContext:(NSManagedObjectContext * _Nonnull)moc
                                             externalData:(NSData * _Nullable)externalData;

@end

@interface ZMClientMessage (External)

+ (NSData * _Nullable)encryptedMessageDataWithExternalDataBlobFromMessage:(ZMGenericMessage * _Nonnull)message
                                                 inConversation:(ZMConversation * _Nonnull)conversation
                                           managedObjectContext:(NSManagedObjectContext * _Nonnull)context;

@end

@interface ZMClientMessage (ZMImageOwner) <ZMImageOwner>

@end
