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


#import "ZMClientMessage.h"

extern NSString * _Nonnull const ZMAssetClientMessage_NeedsToUploadPreviewKey;
extern NSString * _Nonnull const ZMAssetClientMessage_NeedsToUploadMediumKey;
extern NSString * _Nonnull const ZMAssetClientMessage_NeedsToUploadNotUploadedKey;
extern NSString * _Nonnull const ZMAssetClientMessageTransferStateKey;
extern NSString * _Nonnull const ZMAssetClientMessageProgressKey;
extern NSString * _Nonnull const ZMAssetClientMessageLoadedMediumDataKey;
extern NSString * _Nonnull const ZMAssetClientMessageDidCancelFileDownloadNotificationName;

/**
 *  This protocol is used to encapsulate the information and data about an image asset
 */
@protocol ZMImageAssetStorage <ZMImageOwner>

/// Metadata of the medium representation of the image
@property (nonatomic, readonly) ZMGenericMessage * _Nullable previewGenericMessage;

/// Metadata of the preview representation of the image
@property (nonatomic, readonly) ZMGenericMessage * _Nullable mediumGenericMessage;

- (_Nullable instancetype)updateMessageWithImageData:(NSData * _Nonnull)imageData forFormat:(ZMImageFormat)format;

- (NSData * _Nullable)imageDataForFormat:(ZMImageFormat)format encrypted:(BOOL)encrypted;

- (ZMOtrAssetMeta * _Nullable)encryptedMessagePayloadForImageFormat:(ZMImageFormat)imageFormat;

// returns whether image data should be reprocessed
- (BOOL)shouldReprocessForFormat:(ZMImageFormat)format;

- (ZMGenericMessage * _Nullable )genericMessageForFormat:(ZMImageFormat)format;

@end


typedef NS_ENUM(NSUInteger, ZMAssetClientMessageDataType) {
    ZMAssetClientMessageDataTypePlaceholder = 1,
    ZMAssetClientMessageDataTypeFileData = 2
};


@interface ZMAssetClientMessage : ZMOTRMessage

/// Whether it needs to upload the preview
@property (nonatomic, readonly) BOOL needsToUploadPreview;

/// Whether it needs to upload the medium
@property (nonatomic, readonly) BOOL needsToUploadMedium;

/// Remote asset ID
@property (nonatomic) NSUUID * _Nullable assetId;

/// Whether the asset was delivered
@property (nonatomic) BOOL delivered;

/// MIME type of the file being transfered (implied from file extension)
@property (nonatomic, readonly) NSString * _Nonnull mimeType;

/// Original file size
@property (nonatomic, readonly) unsigned long long size;

/// Currend download / upload progress
@property (nonatomic) float progress;

/// File transfer state
@property (nonatomic) ZMFileTransferState transferState;

/// File name as was sent or @c nil in case of an image asset
@property (nonatomic, readonly) NSString * _Nullable filename;

/// Whether the medium representation was downloaded. The preview is always downloaded as it is in-line
@property (nonatomic, readonly) BOOL loadedMediumData;

// The image metaData if if this @c ZMAssetClientMessage represents an image or @c nil otherwise
@property (nonatomic, readonly) id <ZMImageAssetStorage> _Nullable imageAssetStorage;

/// Used to associate and persist the task identifier of the @c NSURLSessionTask
/// with the upload or download of the file data. Can be used to verify that the
/// data of a @c FileMessage is being down- or uploaded after a termination event
@property (nonatomic) ZMTaskIdentifier * _Nullable associatedTaskIdentifier;


- (void)setNeedsToUploadData:(ZMAssetClientMessageDataType)dataType needsToUpload:(BOOL)needsToUpload;

/// Creates a new @c ZMAssetClientMessage with an attached @c imageAssetStorage
+ (instancetype _Nonnull)assetClientMessageWithOriginalImageData:(NSData * _Nonnull)imageData
                                                  nonce:(NSUUID * _Nonnull)nonce
                                   managedObjectContext:(NSManagedObjectContext * _Nonnull)moc;

/// Inserts a new @c ZMAssetClientMessage in the @c moc and updates it with
/// the given parameters, used when sending a file
+ (instancetype _Nonnull)assetClientMessageWithAssetURL:(NSURL * _Nonnull)fileURL
                                          size:(unsigned long long)size
                                      mimeType:(NSString * _Nonnull)mimeType
                                          name:(NSString * _Nonnull)name
                                         nonce:(NSUUID * _Nonnull)nonce
                          managedObjectContext:(NSManagedObjectContext * _Nonnull)moc;

/// Adds a (protobuf) data entry to the list of generic message data
- (void)addGenericMessage:(ZMGenericMessage * _Nonnull)genericMessage;

/// Returns the binary data of the encrypted @c Asset.Uploaded protobuf message or @c nil
/// in case the receiver does not contain a @c Asset.Uploaded generic message.
/// Also returns @c nil for messages representing an image
- (NSData * _Nullable)encryptedMessagePayloadForDataType:(ZMAssetClientMessageDataType)dataType;

/// Marks file to be downloaded. @c state is immediately changed to @c .Downloading. When the download is done the state
/// is changing either to @c .Downloaded or @c .FailedDownload. Progress and state can be observed via message observer.
- (void)requestFullContent;

- (void)didFailToUploadFileData;

@end

