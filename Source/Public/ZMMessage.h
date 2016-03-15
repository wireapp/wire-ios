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


#import <zmessaging/ZMManagedObject.h>
#import <CoreGraphics/CoreGraphics.h>

@class ZMUser;
@class ZMConversation;
@class UserClient;

@protocol ZMImageMessageData;
@protocol ZMSystemMessageData;
@protocol ZMKnockMessageData;
@protocol UserClientType;

typedef NS_ENUM(NSUInteger, ZMDeliveryState) {
    ZMDeliveryStateInvalid = 0,
    ZMDeliveryStatePending = 1,
    ZMDeliveryStateDelivered = 2,
    ZMDeliveryStateFailedToSend = 3
};



@protocol ZMConversationMessage <NSObject>

/// Whether the message was received in its encrypted form.
/// In the transition period, a message can be both encrypted and plaintext.
@property (nonatomic, readonly) BOOL isEncrypted;

/// Whether the message was received in its plain-text form.
/// In the transition period, a message can be both encrypted and plaintext.
@property (nonatomic, readonly) BOOL isPlainText;

/// The user who sent the message
@property (nonatomic, readonly) ZMUser *sender;

/// The timestamp as received by the server
@property (nonatomic, readonly) NSDate *serverTimestamp;

/// The conversation this message belongs to
@property (nonatomic, readonly) ZMConversation *conversation;

/// The current delivery state of this message. It makes sense only for
/// messages sent from this device. In any other case, it will be
/// ZMDeliveryStateDelivered
@property (nonatomic, readonly) ZMDeliveryState deliveryState;

/// The text of the message. If the message has no text, it will be nil
@property (nonatomic, readonly) NSString *messageText;

/// The image data associated with the message. If the message has no image, it will be nil
@property (nonatomic, readonly) id<ZMImageMessageData> imageMessageData;

/// The system message data associated with the message. If the message is not a system message data associated, it will be nil
@property (nonatomic, readonly) id<ZMSystemMessageData> systemMessageData;

/// The knock message data associated with the message. If the message is not a knock, it will be nil
@property (nonatomic, readonly) id<ZMKnockMessageData> knockMessageData;

/// Request the download of the full message content (asset, ...), if not already present.
/// The download will be executed asynchronously. The caller can be notified by observing the message window.
/// This method can safely be called multiple times, even if the content is already available locally
- (void)requestFullContent;

/// In case this message failed to deliver, this will resend it
- (void)resend;

@end



@protocol ZMImageMessageData <NSObject>

@property (nonatomic, readonly) NSData *mediumData; ///< N.B.: Will go away from public header
@property (nonatomic, readonly) NSData *imageData; ///< This will either returns the mediumData or the original image data. Usefull only for newly inserted messages.
@property (nonatomic, readonly) NSString *imageDataIdentifier; /// This can be used as a cache key for @c -imageData

@property (nonatomic, readonly) NSData *previewData;
@property (nonatomic, readonly) NSString *imagePreviewDataIdentifier; /// This can be used as a cache key for @c -previewData
@property (nonatomic, readonly) BOOL isAnimatedGIF; // If it is GIF and has more than 1 frame
@property (nonatomic, readonly) NSString *imageType; // UTI e.g. kUTTypeGIF

@property (nonatomic, readonly) CGSize originalSize;

@end



typedef NS_ENUM(int16_t, ZMSystemMessageType) {
    ZMSystemMessageTypeInvalid = 0,
    ZMSystemMessageTypeParticipantsAdded,
    ZMSystemMessageTypeParticipantsRemoved,
    ZMSystemMessageTypeConversationNameChanged,
    ZMSystemMessageTypeConnectionRequest,
    ZMSystemMessageTypeConnectionUpdate,
    ZMSystemMessageTypeMissedCall,
    ZMSystemMessageTypeNewClient,
    ZMSystemMessageTypeIgnoredClient,
    ZMSystemMessageTypeConversationIsSecure,
    ZMSystemMessageTypePotentialGap,
    ZMSystemMessageTypeDecryptionFailed,
    ZMSystemMessageTypeDecryptionFailed_RemoteIdentityChanged
};



@protocol ZMSystemMessageData <NSObject>

@property (nonatomic, readonly) ZMSystemMessageType systemMessageType;
@property (nonatomic, readonly) NSSet <ZMUser *>*users;
@property (nonatomic, readonly) NSSet <id<UserClientType>>*clients;
@property (nonatomic) NSSet<ZMUser *> *addedUsers; // Only filled for ZMSystemMessageTypePotentialGap
@property (nonatomic) NSSet<ZMUser *> *removedUsers; // Only filled for ZMSystemMessageTypePotentialGap
@property (nonatomic, readonly, copy) NSString *text;
@property (nonatomic) BOOL needsUpdatingUsers;

@end

@protocol ZMKnockMessageData <NSObject>

@end

