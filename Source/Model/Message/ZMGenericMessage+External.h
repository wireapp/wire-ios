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


@import WireProtos;
@class ZMUpdateEvent;

@interface ZMEncryptionKeyWithChecksum: NSObject

/// AES Key used for the symmetric encryption of the data
@property (nonatomic, readonly) NSData *aesKey;
/// SHA-256 digest
@property (nonatomic, readonly) NSData *sha256;

+ (ZMEncryptionKeyWithChecksum *)keyWithAES:(NSData *)aesKey digest:(NSData *)sha256;

@end


@interface ZMExternalEncryptedDataWithKeys : NSObject

/// The encrypted data
@property (nonatomic, readonly) NSData *data;
/// The AES Key used to encrypt @c data and the sha-256 digest of @c data
@property (nonatomic, readonly) ZMEncryptionKeyWithChecksum *keys;

+ (ZMExternalEncryptedDataWithKeys *)dataWithKeysWithData:(NSData *)data keys:(ZMEncryptionKeyWithChecksum *)keys;

@end


@interface ZMGenericMessage (External)

/// @abstract Helper to generate the payload for a generic message of type @c external
/// @discussion In case the payload of a regular (text) message is to large,
/// we need to symmetrically encrypt the original generic message using a generated
/// symmetric key. A generic message of type @c external which contains the key
/// used for the symmetric encryption and the sha-256 checksum og the encoded data needs to be created.
/// When sending the @c external message the encrypted original message should be attached to the payload
/// in the @c blob field of the protocol buffer.
/// @param message The message that should be encrypted to sent it as attached payload in a @c external message
/// @return The encrypted original message, the encryption key and checksum warpped in a @c ZMExternalEncryptedDataWithKeys
+ (ZMExternalEncryptedDataWithKeys *)encryptedDataWithKeysFromMessage:(ZMGenericMessage *)message;

/// @abstract Creates a genericMessage from a @c ZMUpdateEvent and @c ZMExternal
/// @discussion The symetrically encrypted data (representing the original @c ZMGenericMessage)
/// contained in the update event will be decrypted using the encryption keys in the @c ZMExternal
/// @param updateEvent The decrypted @c ZMUpdateEvent containing the external data
/// @param external @c The @c ZMExternal containing the otrKey used for the symmetric encryption and the sha256 checksum
/// @return The decrypted original @c ZMGenericMessage that was contained in the update event
+ (ZMGenericMessage *)genericMessageFromUpdateEventWithExternal:(ZMUpdateEvent *)updateEvent external:(ZMExternal *)external;

@end
