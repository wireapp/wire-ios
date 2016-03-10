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


#import "ZMClientMessage.h"

extern NSString * const ZMAssetClientMessage_NeedsToUploadPreviewKey;
extern NSString * const ZMAssetClientMessage_NeedsToUploadMediumKey;

@interface ZMAssetClientMessage : ZMOTRMessage <ZMConversationMessage>

/// Whether it needs to upload the preview
@property (nonatomic, readonly) BOOL needsToUploadPreview;

/// Whether it needs to upload the medium
@property (nonatomic, readonly) BOOL needsToUploadMedium;

/// Metadata of the medium representation of the image
@property (nonatomic, readonly) ZMGenericMessage *previewGenericMessage;

/// Metadata of the preview representation of the image
@property (nonatomic, readonly) ZMGenericMessage *mediumGenericMessage;

/// Remote asset ID
@property (nonatomic) NSUUID *assetId;

/// Whether the image was delivered
@property (nonatomic) BOOL delivered;

/// Whether the medium representation was downloaded. The preview is always downloaded as it is in-line
@property (nonatomic, readonly) BOOL loadedMediumData;


+ (instancetype)assetClientMessageWithOriginalImageData:(NSData *)imageData
                                                  nonce:(NSUUID *)nonce
                                   managedObjectContext:(NSManagedObjectContext *)moc;

- (instancetype)updateMessageWithImageData:(NSData *)imageData forFormat:(ZMImageFormat)format;

- (ZMGenericMessage *)genericMessageForFormat:(ZMImageFormat)format;

// returns whether image data should be reprocessed
- (BOOL)shouldReprocessForFormat:(ZMImageFormat)format;

/// Adds a (protobuf) data entry to the list of generic message data
- (void)addGenericMessage:(ZMGenericMessage *)genericMessage;

/// Sets whether it needs to upload one of the formats
- (void)setNeedsToUploadFormat:(ZMImageFormat)format needsToUpload:(BOOL)needsToUpload;

@end

@interface ZMAssetClientMessage (ImageOwner) <ZMImageOwner>

- (NSData *)imageDataForFormat:(ZMImageFormat)format encrypted:(BOOL)encrypted;

@end



@interface ZMAssetClientMessage (OTR)

- (ZMOtrAssetMeta *)encryptedMessagePayloadForImageFormat:(ZMImageFormat)imageFormat;

@end
