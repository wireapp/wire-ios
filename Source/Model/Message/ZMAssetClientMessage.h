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


#import "ZMClientMessage.h"

@class ZMFileMetadata;

extern NSString * _Nonnull const ZMAssetClientMessageTransferStateKey;
extern NSString * _Nonnull const ZMAssetClientMessageProgressKey;
extern NSString * _Nonnull const ZMAssetClientMessageDownloadedImageKey;
extern NSString * _Nonnull const ZMAssetClientMessageDownloadedFileKey;
extern NSString * _Nonnull const ZMAssetClientMessageDidCancelFileDownloadNotificationName;
extern NSString * _Nonnull const ZMAssetClientMessageUploadedStateKey;

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

// returns whether image data should be reprocessed
- (BOOL)shouldReprocessForFormat:(ZMImageFormat)format;

- (ZMGenericMessage * _Nullable )genericMessageForFormat:(ZMImageFormat)format;

- (CGSize)preprocessedSize;

@end


typedef NS_ENUM(NSUInteger, ZMAssetClientMessageDataType) {
    ZMAssetClientMessageDataTypePlaceholder = 1,
    ZMAssetClientMessageDataTypeFullAsset = 2,
    ZMAssetClientMessageDataTypeThumbnail = 3,
};

typedef NS_ENUM(int16_t, ZMAssetUploadState) {
    ZMAssetUploadStateDone = 0,
    ZMAssetUploadStateUploadingPlaceholder = 1,
    ZMAssetUploadStateUploadingThumbnail = 2,
    ZMAssetUploadStateUploadingFullAsset = 3,
    ZMAssetUploadStateUploadingFailed = 4
};


@interface ZMAssetClientMessage : ZMOTRMessage

/// The generic asset message containing that is constructed by merging
/// all generic messages from the dataset that contain an asset
@property (nonatomic, readonly) ZMGenericMessage * _Nullable genericAssetMessage;

/// Remote asset ID
@property (nonatomic) NSUUID * _Nullable assetId;

/// Whether the asset was delivered to the Backend
@property (nonatomic) BOOL delivered;


@property (nonatomic, readonly) CGSize preprocessedSize;

/// MIME type of the file being transfered (implied from file extension)
@property (nonatomic, readonly) NSString * _Nullable mimeType;

/// Original file size
@property (nonatomic, readonly) unsigned long long size;

/// Currend download / upload progress
@property (nonatomic) float progress;

/// File transfer state
@property (nonatomic) ZMFileTransferState transferState;

/// Upload state
@property (nonatomic) ZMAssetUploadState uploadState;

/// File name as was sent or @c nil in case of an image asset
@property (nonatomic, readonly) NSString * _Nullable filename;

/// Whether the image was downloaded
@property (nonatomic, readonly) BOOL hasDownloadedImage;

/// Whether the file was downloaded
@property (nonatomic, readonly) BOOL hasDownloadedFile;

/// The asset endpoint version used to generate this message
/// values lower than 3 represent an enpoint version of 2
@property (nonatomic, readonly) int16_t version;

// The image metaData if if this @c ZMAssetClientMessage represents an image or @c nil otherwise
@property (nonatomic, readonly) id <ZMImageAssetStorage> _Nullable imageAssetStorage;

/// Used to associate and persist the task identifier of the @c NSURLSessionTask
/// with the upload or download of the file data. Can be used to verify that the
/// data of a @c FileMessage is being down- or uploaded after a termination event
@property (nonatomic) ZMTaskIdentifier * _Nullable associatedTaskIdentifier;

/// Creates a new @c ZMAssetClientMessage with an attached @c imageAssetStorage
+ (instancetype _Nonnull)assetClientMessageWithOriginalImageData:(NSData * _Nonnull)imageData
                                                           nonce:(NSUUID * _Nonnull)nonce
                                            managedObjectContext:(NSManagedObjectContext * _Nonnull)moc
                                                    expiresAfter:(NSTimeInterval)timeout;

/// Inserts a new @c ZMAssetClientMessage in the @c moc and updates it with the given file metadata
+ (nonnull instancetype)assetClientMessageWithFileMetadata:(nonnull ZMFileMetadata *)metadata
                                                     nonce:(nonnull NSUUID *)nonce
                                      managedObjectContext:(nonnull NSManagedObjectContext *)moc
                                              expiresAfter:(NSTimeInterval)timeout;

+ (nonnull instancetype)assetClientMessageWithFileMetadata:(nonnull ZMFileMetadata *)metadata
                                                     nonce:(nonnull NSUUID *)nonce
                                      managedObjectContext:(nonnull NSManagedObjectContext *)moc
                                              expiresAfter:(NSTimeInterval)timeout
                                                  version3:(BOOL)version3;

/// Adds a (protobuf) data entry to the list of generic message data
- (void)addGenericMessage:(ZMGenericMessage * _Nonnull)genericMessage;

/// Marks file to be downloaded
- (void)requestFileDownload;

- (void)didFailToUploadFileData;

@end

