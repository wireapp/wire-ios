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


#import "CBSession.h"
#import "CBTypes.h"

#import "cbox.h"
#import "CBTypes.h"
#import "CBMacros.h"
#import "CBPreKey.h"
#import "CBVector+Internal.h"
#import "CBSession+Internal.h"
#import "CBCryptoBox+Internal.h"


@interface CBSession () {
    CBoxSessionRef _sessionBacking;
}

@property (nonatomic, readwrite, copy) NSString *sessionId;
@property (nonatomic) dispatch_queue_t sessionQueue;

@end

@implementation CBSession

- (void)dealloc
{
    if (_sessionBacking != NULL) {
        [self closeInternally];
    }
}

- (BOOL)save:(NSError *__autoreleasing  _Nullable *)error
{
    __block BOOL success = NO;
    dispatch_sync(self.sessionQueue, ^{
        CBThrowIllegalStageExceptionIfClosed([self isClosedInternally]);
        
        CBoxResult result = cbox_session_save(self.box.box, self->_sessionBacking);
        CBAssertResultIsSuccess(result);
        CBReturnWithErrorIfNotSuccess(result, error);
        
        success = YES;
    });

    return success;
}

- (BOOL)isClosed
{
    __block BOOL closed;
    dispatch_sync(self.sessionQueue, ^{
        closed = [self isClosedInternally];
    });
    return closed;
}

- (nullable NSData *)encrypt:(NSData *)plain error:(NSError *__autoreleasing  _Nullable *)error
{
    __block NSData *data = nil;
    dispatch_sync(self.sessionQueue, ^{
        NSParameterAssert(plain);
        
        CBThrowIllegalStageExceptionIfClosed([self isClosedInternally]);
        
        CBoxVecRef cipher = NULL;
        const uint8_t *bytes = (const uint8_t*)plain.bytes;
        if (bytes == NULL) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"plain not set" userInfo:nil];
        }
        
        CBoxResult result = cbox_encrypt(self->_sessionBacking, bytes, (uint32_t)plain.length, &cipher);
        //CBAssertResultIsSuccess(result);
        CBReturnWithErrorIfNotSuccess(result, error);

        CBVector *vector = [[CBVector alloc] initWithCBoxVecRef:cipher];
        data = vector.data;
    });
    return data;
}

- (nullable NSData *)decrypt:(NSData *)cipher error:(NSError *__autoreleasing  _Nullable *)error
{
    __block NSData *data = nil;
    dispatch_sync(self.sessionQueue, ^{
        NSParameterAssert(cipher);
        
        CBThrowIllegalStageExceptionIfClosed([self isClosedInternally]);
        
        const uint8_t *bytes = (const uint8_t*)cipher.bytes;
        if (bytes == NULL) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"cipher not set" userInfo:nil];
        }
        CBoxVecRef plain = NULL;
        CBoxResult result = cbox_decrypt(self->_sessionBacking, bytes, (uint32_t)cipher.length, &plain);
        //CBAssertResultIsSuccess(result);
        CBReturnWithErrorIfNotSuccess(result, error);
        
        CBVector *vector = [[CBVector alloc] initWithCBoxVecRef:plain];
        
        data = vector.data;
    });
    return data;
}

- (nullable NSData *)remoteFingerprint
{
    __block NSData *fingerprint = nil;
    dispatch_sync(self.sessionQueue, ^{
        if ([self isClosedInternally]) {
            return;
        }
        CBoxVecRef vectorBacking = NULL;
        cbox_fingerprint_remote(self->_sessionBacking, &vectorBacking);
        fingerprint = [CBVector vectorWithCBoxVecRef:vectorBacking].data;
    });
    return fingerprint;
}

#pragma mark -

- (void)closeInternally
{
    cbox_session_close(_sessionBacking);
    _sessionBacking = NULL;
}

- (BOOL)isClosedInternally
{
    return (_sessionBacking == NULL);
}

@end



@implementation CBSession (Internal)

- (nonnull instancetype)initWithCBoxSessionRef:(nonnull CBoxSessionRef)session sessionId:(NSString *)sId
{
    self = [super init];
    if (self) {
        _sessionBacking = session;
        // TODO: Can we use here DISPATCH_QUEUE_CONCURRENT check
        self.sessionQueue = dispatch_queue_create("org.pkaboo.cryptobox.sessionQueue", DISPATCH_QUEUE_SERIAL);
        self.sessionId = sId;
    }
    return self;
}

- (void)close
{
    dispatch_sync(self.sessionQueue, ^{
        if ([self isClosedInternally]) {
            return;
        }
        [self closeInternally];
    });
}

@end
