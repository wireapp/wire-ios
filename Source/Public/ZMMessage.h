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


#import "ZMManagedObject.h"
#import <CoreGraphics/CoreGraphics.h>

@class ZMUser;
@class ZMConversation;
@class UserClient;
@class LinkPreview;

@protocol ZMImageMessageData;
@protocol ZMSystemMessageData;
@protocol ZMKnockMessageData;
@protocol ZMFileMessageData;
@protocol UserClientType;


#pragma mark - ZMImageMessageData


@protocol ZMImageMessageData <NSObject>

@property (nonatomic, readonly) NSData *imageData; ///< This will either returns the mediumData or the original image data. Useful only for newly inserted messages.
@property (nonatomic, readonly) NSString *imageDataIdentifier; /// This can be used as a cache key for @c -imageData

@property (nonatomic, readonly) BOOL isAnimatedGIF; // If it is GIF and has more than 1 frame
@property (nonatomic, readonly) BOOL isDownloaded; // If it is GIF and has more than 1 frame
@property (nonatomic, readonly) NSString *imageType; // UTI e.g. kUTTypeGIF
@property (nonatomic, readonly) CGSize originalSize;

- (void)fetchImageDataWithQueue:(dispatch_queue_t)queue completionHandler:(void (^)(NSData *imageData))completionHandler;

@end


#pragma mark - ZMSystemMessageData


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
    ZMSystemMessageTypeDecryptionFailed_RemoteIdentityChanged,
    ZMSystemMessageTypeNewConversation,
    ZMSystemMessageTypeReactivatedDevice,
    ZMSystemMessageTypeUsingNewDevice,
    ZMSystemMessageTypeMessageDeletedForEveryone,
    ZMSystemMessageTypePerformedCall,
    ZMSystemMessageTypeTeamMemberLeave,
    ZMSystemMessageTypeMessageTimerUpdate
};



@protocol ZMTextMessageData <NSObject>

@property (nonatomic, readonly) NSString *messageText;
@property (nonatomic, readonly) LinkPreview *linkPreview;

/// Returns true if the link preview will have an image
@property (nonatomic, readonly) BOOL linkPreviewHasImage;

/// Unique identifier for imageData. Returns nil there's not imageData associated with the message.
@property (nonatomic, readonly) NSString *linkPreviewImageCacheKey;

/// Fetch linkpreview image data from disk on the given queue
- (void)fetchLinkPreviewImageDataWithQueue:(dispatch_queue_t)queue completionHandler:(void (^)(NSData *imageData))completionHandler;

@end


@protocol ZMSystemMessageData <NSObject>

@property (nonatomic, readonly) ZMSystemMessageType systemMessageType;
@property (nonatomic, readonly) NSSet <ZMUser *>*users;
@property (nonatomic, readonly) NSSet <id<UserClientType>>*clients;
@property (nonatomic) NSSet<ZMUser *> *addedUsers; // Only filled for ZMSystemMessageTypePotentialGap
@property (nonatomic) NSSet<ZMUser *> *removedUsers; // Only filled for ZMSystemMessageTypePotentialGap
@property (nonatomic, readonly, copy) NSString *text;
@property (nonatomic) BOOL needsUpdatingUsers;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) NSSet<id <ZMSystemMessageData>>  *childMessages;
@property (nonatomic) id <ZMSystemMessageData> parentMessage;
@property (nonatomic, readonly) BOOL userIsTheSender;
@property (nonatomic) NSNumber *messageTimer;

@end


#pragma mark - ZMKnockMessageData


@protocol ZMKnockMessageData <NSObject>

@end

typedef NS_ENUM(int16_t, ZMLinkPreviewState) {
    /// Link preview has been sent or message did not contain any preview
    ZMLinkPreviewStateDone = 0,
    /// Message text needs to be parsed to see if it contain any links
    ZMLinkPreviewStateWaitingToBeProcessed,
    /// Link preview have been downloaded
    ZMLinkPreviewStateDownloaded,
    /// Link preview assets have been processed & encrypted
    ZMLinkPreviewStateProcessed,
    /// Link preview assets have been uploaded
    ZMLinkPreviewStateUploaded
};

typedef NS_ENUM(int16_t, ZMFileTransferState) {
    /// Initial file state when sender is initiating the transfer to BE.
    ZMFileTransferStateUploading,
    /// File is uploaded to the backend. Sender and receiver are able to open the file.
    ZMFileTransferStateUploaded,
    /// File is being downloaded from the backend to the client.
    ZMFileTransferStateDownloading,
    /// File is downloaded to the client, it is possible to open it.
    ZMFileTransferStateDownloaded,
    /// File was failed to upload to backend.
    ZMFileTransferStateFailedUpload,
    /// File upload was cancelled by the sender.
    ZMFileTransferStateCancelledUpload,
    /// File is on backend, but it was failed to download to the client.
    ZMFileTransferStateFailedDownload,
    /// File is not available on the backend anymore.
    ZMFileTransferStateUnavailable
};


#pragma mark - ZMLocationMessageData

@protocol ZMLocationMessageData <NSObject>

@property (nonatomic, readonly) float longitude;
@property (nonatomic, readonly) float latitude;

@property (nonatomic, readonly) NSString *name; // nil if not specified
@property (nonatomic, readonly) int32_t zoomLevel; // 0 if not specified

@end

