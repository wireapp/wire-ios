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


#import "ZMGenericMessage+External.h"
#import "ZMGenericMessage+UpdateEvent.h"


@import WireTransport;
@import WireUtilities;


#pragma mark - ZMEncryptionKeyWithChecksum


@interface ZMEncryptionKeyWithChecksum ()
@property (nonatomic, readwrite) NSData *aesKey;
@property (nonatomic, readwrite) NSData *sha256;
@end

@implementation ZMEncryptionKeyWithChecksum

- (instancetype)initWithAES:(NSData *)aesKey digest:(NSData *)sha256
{
    self = [super init];
    if (self)  {
        self.aesKey = aesKey;
        self.sha256 = sha256;
    }
    return self;
}

+ (ZMEncryptionKeyWithChecksum *)keyWithAES:(NSData *)aesKey digest:(NSData *)sha256
{
    return [[self alloc] initWithAES:aesKey digest:sha256];
}

- (BOOL)isEqual:(id)object
{
    if (! [object isKindOfClass:ZMEncryptionKeyWithChecksum.class]) {
        return NO;
    }
    
    ZMEncryptionKeyWithChecksum *other = object;
    return [self.aesKey isEqualToData:other.aesKey] && [self.sha256 isEqualToData:other.sha256];
}

@end


#pragma mark - ZMExternalEncryptedDataWithKeys


@interface ZMExternalEncryptedDataWithKeys ()
@property (nonatomic, readwrite) NSData *data;
@property (nonatomic, readwrite) ZMEncryptionKeyWithChecksum *keys;
@end

@implementation ZMExternalEncryptedDataWithKeys

- (instancetype)initWithData:(NSData *)data keys:(ZMEncryptionKeyWithChecksum *)keys
{
    self = [super init];
    if (self)  {
        self.data = data;
        self.keys = keys;
    }
    return self;
}

+ (ZMExternalEncryptedDataWithKeys *)dataWithKeysWithData:(NSData *)data keys:(ZMEncryptionKeyWithChecksum *)keys
{
    return [[self alloc] initWithData:data keys:keys];
}

- (BOOL)isEqual:(id)object
{
    if (! [object isKindOfClass:ZMExternalEncryptedDataWithKeys.class]) {
        return NO;
    }
    
    ZMExternalEncryptedDataWithKeys *other = object;
    return [self.data isEqualToData:other.data] && [self.keys isEqual:other.keys];
}

@end


#pragma mark - ZMGenericMessage


@implementation ZMGenericMessage (External)

+ (ZMExternalEncryptedDataWithKeys *)encryptedDataWithKeysFromMessage:(ZMGenericMessage *)message
{
    NSData *aesKey = NSData.randomEncryptionKey;
    NSData *encryptedData = [message.data zmEncryptPrefixingPlainTextIVWithKey:aesKey];
    ZMEncryptionKeyWithChecksum *keys = [ZMEncryptionKeyWithChecksum keyWithAES:aesKey digest:encryptedData.zmSHA256Digest];
    return [ZMExternalEncryptedDataWithKeys dataWithKeysWithData:encryptedData keys:keys];
}

+ (ZMGenericMessage *)genericMessageFromUpdateEventWithExternal:(ZMUpdateEvent *)updateEvent external:(ZMExternal *)external
{
    NSData *sha256 = external.sha256;
    NSData *otrKey = external.otrKey;
    VerifyReturnNil(nil != sha256);
    VerifyReturnNil(nil != otrKey);
    
    NSString *externalDataString = [updateEvent.payload optionalStringForKey:@"external"];
    VerifyReturnNil(nil != externalDataString);
    NSData *externalData = [[NSData alloc] initWithBase64EncodedString:externalDataString options:0];
    NSData *externalSha256 = externalData.zmSHA256Digest;
    
    if (! [externalSha256 isEqualToData:sha256]) {
        ZMLogError(@"Invalid hash for external data: %@ != %@, updateEvent: %@", externalSha256, sha256, updateEvent);
        return nil;
    }
    
    NSData *decryptedData = [externalData zmDecryptPrefixedPlainTextIVWithKey:otrKey];
    VerifyReturnNil(nil != decryptedData);
    
    return [self genericMessageWithBase64String:decryptedData.base64String updateEvent:updateEvent];
}

@end
