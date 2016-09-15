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


@import UIKit;
@import zimages;

#import <ZMProtos/ZMProtos.h>

@class ZMIImageProperties;
@class ZMConversation;

@interface ZMImageAssetEncryptionKeys: NSObject

/// Key used for symmetric encryption of the asset
@property (nonatomic, copy, readonly) NSData *otrKey;
/// HMAC key used to compute the digest
@property (nonatomic, copy, readonly) NSData *macKey;
/// HMAC digest
@property (nonatomic, copy, readonly) NSData *mac;
/// SHA-256 digest
@property (nonatomic, copy, readonly) NSData *sha256;
/// Wether it has a HMAC digest
@property (nonatomic, readonly) BOOL hasHMACDigest;
/// Wether it has a SHA256 digest
@property (nonatomic, readonly) BOOL hasSHA256Digest;


- (instancetype)initWithOtrKey:(NSData *)otrKey macKey:(NSData *)macKey mac:(NSData *)mac;
- (instancetype)initWithOtrKey:(NSData *)otrKey sha256:(NSData *)sha256;

@end


@interface ZMGenericMessage (Utils)

+ (ZMGenericMessage *)messageWithBase64String:(NSString *)string;
+ (ZMGenericMessage *)knockWithNonce:(NSString *)nonce;
+ (ZMGenericMessage *)sessionResetWithNonce:(NSString *)nonce;
+ (ZMGenericMessage *)messageWithText:(NSString *)message nonce:(NSString *)nonce;
+ (ZMGenericMessage *)messageWithText:(NSString *)message linkPreview:(ZMLinkPreview *)linkPreview nonce:(NSString *)nonce;
+ (ZMGenericMessage *)messageWithImageData:(NSData *)imageData format:(ZMImageFormat)format nonce:(NSString *)nonce;
+ (ZMGenericMessage *)messageWithConfirmation:(NSString *)messageID type:(ZMConfirmationType)type nonce:(NSString *)nonce;


+ (ZMGenericMessage *)messageWithMediumImageProperties:(nullable ZMIImageProperties *)mediumProperties
                              processedImageProperties:(nullable ZMIImageProperties *)processedProperties
                                        encryptionKeys:(nullable ZMImageAssetEncryptionKeys *)encryptionKeys
                                                 nonce:(NSString *)nonce
                                                format:(ZMImageFormat)format;

+ (ZMGenericMessage *)messageWithLastRead:(NSDate *)timestamp
                     ofConversationWithID:(NSString *)conversationIDString
                                    nonce:(NSString *)nonce;

+ (ZMGenericMessage *)messageWithClearedTimestamp:(NSDate *)timestamp
                     ofConversationWithID:(NSString *)conversationIDString
                                    nonce:(NSString *)nonce;

+ (ZMGenericMessage *)messageWithHideMessage:(NSString *)messageID
                              inConversation:(NSString *)conversationID
                                       nonce:(NSString *)nonce;

+ (ZMGenericMessage *)messageWithDeleteMessage:(NSString *)messageID
                                         nonce:(NSString *)nonce;

+ (ZMGenericMessage *)messageWithEditMessage:(NSString *)messageID
                                     newText:(NSString *)newText
                                       nonce:(NSString *)nonce;

+ (ZMGenericMessage *)messageWithEditMessage:(NSString *)messageID
                                     newText:(NSString *)newText
                                 linkPreview:(ZMLinkPreview *)linkPreview
                                       nonce:(NSString *)nonce;


+ (ZMGenericMessage *)messageWithEmojiString:(NSString *)emojiString
                                   messageID:(NSString *)messageID
                                       nonce:(NSString *)nonce;
- (BOOL)knownMessage;

@end

@interface ZMImageAsset (Utils)

- (ZMImageFormat)imageFormat;

@end
