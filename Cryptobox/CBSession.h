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


#import <Foundation/Foundation.h>

@class CBCryptoBox;

@interface CBSession : NSObject

@property (nonatomic, readonly, copy, nonnull) NSString *sessionId;
@property (nonatomic, weak, nullable) CBCryptoBox *box;


/// @throws CBCodeIllegalStateException in case @c CBCryptoBox is closed already
- (BOOL)save:(NSError *__nullable * __nullable)error;

/// Encrypt a byte array containing plaintext.
/// @throws NSInvalidArgumentException  in case @c plain is nil
/// @throws CBCodeIllegalStateException in case @c CBCryptoBox is closed already
- (nullable NSData *)encrypt:(nonnull NSData *)plain error:(NSError *__nullable * __nullable)error;

/// Decrypt a byte array containing plaintext.
/// @throws NSInvalidArgumentException  in case @c cipher is nil
/// @throws CBCodeIllegalStateException in case @c CBCryptoBox is closed already
- (nullable NSData *)decrypt:(nonnull NSData *)cipher error:(NSError *__nullable * __nullable)error;

/// Get the remote fingerprint as a hex-encoded byte array
- (nullable NSData *)remoteFingerprint;

- (BOOL)isClosed;

@end

