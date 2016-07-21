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


#import "CBCryptoBox.h"
#import "CBTypes.h"

#import "CBSession+Internal.h"
#import "CBVector+Internal.h"
#import "CBPreKey.h"
#import "NSError+Cryptobox.h"
#import "cbox.h"
#import "CBMacros.h"
#import "CBSessionMessage.h"
#import "CBPreKey+Internal.h"
#import "CBCryptoBox+Internal.h"



static dispatch_queue_t CBOpeningQueue(void)
{
    static dispatch_queue_t openingQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        openingQueue = dispatch_queue_create("org.pkaboo.cryptobox.cryptoBoxOpeningQueue", 0);
    });
    return openingQueue;
}



const NSUInteger CBMaxPreKeyID = 0xFFFE;



@interface CBCryptoBox () {
    CBoxRef _boxBacking;
}

@property (nonatomic) dispatch_queue_t cryptoBoxQueue;

/// All the existing sessions
@property (nonatomic) NSMutableDictionary *sessions;

@property (nonatomic) NSMutableSet *sessionsRequiringSave;

@end

@implementation CBCryptoBox

+ (nullable instancetype)cryptoBoxWithPathURL:(nonnull NSURL *)directory error:(NSError *__nullable * __nullable)error
{
    __block CBCryptoBox *cryptoBox = nil;
    dispatch_sync(CBOpeningQueue(), ^{
        NSParameterAssert(directory);
        
        CBoxRef cbox = NULL;
        CBoxResult result = cbox_file_open([directory.path UTF8String], &cbox);
        CBReturnWithErrorIfNotSuccess(result, error);
        
        cryptoBox = [[CBCryptoBox alloc] initWithCBoxRef:cbox];
    });
    return cryptoBox;
}

- (void)dealloc
{
    if (! [self isClosedInternally]) {
        [self closeInternally];
    }
}

- (nullable CBSession *)sessionWithId:(nonnull NSString *)sessionId fromPreKey:(nonnull CBPreKey *)preKey error:(NSError *__autoreleasing  __nullable * __nullable)error
{
    return [self sessionWithId:sessionId
                fromPreKeyData:preKey.data
                         error:error];
}

- (nullable CBSession *)sessionWithId:(nonnull NSString *)sessionId fromStringPreKey:(nonnull NSString *)base64StringKey error:(NSError *__autoreleasing  __nullable * __nullable)error
{
    return [self sessionWithId:sessionId
                fromPreKeyData:[[NSData alloc] initWithBase64EncodedString:base64StringKey options:0]
                         error:error];
}

- (nullable CBSession *)sessionWithId:(nonnull NSString *)sessionId fromPreKeyData:(nonnull NSData *)preKeyData error:(NSError *__autoreleasing  __nullable * __nullable)error
{
    __block CBSession *session = nil;
    
    dispatch_sync(self.cryptoBoxQueue, ^{
        NSParameterAssert(sessionId);
        CBThrowIllegalStageExceptionIfClosed([self isClosedInternally]);
        
        session = [self.sessions objectForKey:sessionId];
        if (session) {
            return;
        }
        
        CBoxResult result;
        CBoxSessionRef sessionBacking = NULL;
        result = cbox_session_init_from_prekey(self->_boxBacking, [sessionId UTF8String], preKeyData.bytes, preKeyData.length, &sessionBacking);
        CBReturnWithErrorIfNotSuccess(result, error);
        
        cbox_session_save(self->_boxBacking, sessionBacking);
        session = [self createNewSessionWithId:sessionId backedBy:sessionBacking];
    });
    
    return session;
}

- (nullable CBSessionMessage *)sessionMessageWithId:(nonnull NSString *)sessionId fromMessage:(nonnull NSData *)message error:(NSError *__nullable * __nullable)error
{
    __block CBSessionMessage *sessionMessage = nil;
    dispatch_sync(self.cryptoBoxQueue, ^{
        NSParameterAssert(sessionId);
        NSParameterAssert(message);
        
        CBThrowIllegalStageExceptionIfClosed([self isClosedInternally]);

        CBSession *session = [self.sessions objectForKey:sessionId];
        NSAssert(! [session isClosed], @"Session is closed");
        if (session) {
            NSData *plain = [session decrypt:message error:error];
            if (! plain) {
                return;
            }
            sessionMessage = [[CBSessionMessage alloc] initWithSession:session data:plain];
        } else {
            CBoxSessionRef sessionBacking = NULL;
            CBoxVecRef plain = NULL;
            const uint8_t *bytes = (const uint8_t*)message.bytes;
            CBoxResult result = cbox_session_init_from_message(self->_boxBacking, [sessionId UTF8String], bytes, (uint32_t)message.length, &sessionBacking, &plain);
            CBReturnWithErrorIfNotSuccess(result, error);

            // Fetch the plain data
            CBVector *vector = [[CBVector alloc] initWithCBoxVecRef:plain];
            // TODO: Unsure about this
            if (! vector.data) {
                if (error != NULL) {
                    *error = [NSError cb_errorWithErrorCode:CBErrorCodeDecodeError];
                }
                return;
            }
            
            session = [self createNewSessionWithId:sessionId backedBy:sessionBacking];
            
            sessionMessage = [[CBSessionMessage alloc] initWithSession:session data:vector.data];
        }
    });
    
    return sessionMessage;
}

- (nullable CBSession *)sessionById:(nonnull NSString *)sessionId error:(NSError *__nullable * __nullable)error
{
    __block CBSession *session = nil;
    dispatch_sync(self.cryptoBoxQueue, ^{
        NSParameterAssert(sessionId);
        
        CBThrowIllegalStageExceptionIfClosed([self isClosedInternally]);
        
        session = [self.sessions objectForKey:sessionId];
        NSAssert(! [session isClosed], @"Session is closed");
        if (! session) {
            CBoxSessionRef sessionBacking = NULL;
            CBoxResult result = cbox_session_load(self->_boxBacking, [sessionId UTF8String], &sessionBacking);
            CBReturnWithErrorIfNotSuccess(result, error);
            
            session = [self createNewSessionWithId:sessionId backedBy:sessionBacking];
        }
    });
    
    return session;
}

- (nonnull CBSession *)createNewSessionWithId:(nonnull NSString *)sessionId backedBy:(nonnull CBoxSessionRef)sessionBacking
{
    CBSession *session = [[CBSession alloc] initWithCBoxSessionRef:sessionBacking sessionId:sessionId];
    session.box = self;
    [self.sessions setObject:session forKey:sessionId];
    return session;
}

- (BOOL)deleteSessionWithId:(NSString *)sessionId error:(NSError *__nullable * __nullable)error
{
    __block BOOL success = NO;
    dispatch_sync(self.cryptoBoxQueue, ^{
        NSParameterAssert(sessionId);
        
        CBThrowIllegalStageExceptionIfClosed([self isClosedInternally]);
        
        CBSession *session = [self.sessions objectForKey:sessionId];
        if (session) {
            [session close];
            [self removeSession:session];
        }
        
        CBoxResult result = cbox_session_delete(self->_boxBacking, [sessionId UTF8String]);
        CBReturnWithErrorIfNotSuccess(result, error);
        
        success = YES;
    });
    
    return success;
}

- (void)setSessionToRequireSave:(CBSession * __nonnull)session;
{
    dispatch_sync(self.cryptoBoxQueue, ^{
        [self.sessionsRequiringSave addObject:session];
    });
}

- (void)saveSessionsRequiringSave;
{
    dispatch_sync(self.cryptoBoxQueue, ^{
        for (CBSession *session in self.sessionsRequiringSave) {
            [session save:NULL];
            
            // we just persisted the session, we remove it from memory to reload a clean version from disk
            [self.sessions removeObjectForKey:session.sessionId];
        }
        [self.sessionsRequiringSave removeAllObjects];
    });
}

- (void)resetSessionsRequiringSave;
{
    dispatch_sync(self.cryptoBoxQueue, ^{
        [self.sessionsRequiringSave removeAllObjects];
    });
}


- (nullable NSData *)localFingerprint:(NSError *__nullable * __nullable __unused)error
{
    __block NSData *data = nil;
    dispatch_sync(self.cryptoBoxQueue, ^{
        CBThrowIllegalStageExceptionIfClosed([self isClosedInternally]);
        
        CBoxVecRef vectorBacking = NULL;
        cbox_fingerprint_local(self->_boxBacking, &vectorBacking);
        CBVector *vector = [[CBVector alloc] initWithCBoxVecRef:vectorBacking];
        data = vector.data;
    });
    
    return data;
}

- (nullable CBPreKey *)lastPreKey:(NSError *__nullable * __nullable)error
{
    __block CBPreKey *key = nil;
    dispatch_sync(self.cryptoBoxQueue, ^{
        CBThrowIllegalStageExceptionIfClosed([self isClosedInternally]);
        
        key = [CBPreKey preKeyWithId:CBOX_LAST_PREKEY_ID boxRef:self->_boxBacking error:error];
    });
    
    return key;
}

- (nullable NSArray *)generatePreKeys:(NSRange)range error:(NSError *__nullable * __nullable)error
{
    if (range.location > CBMaxPreKeyID) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"location must be >= 0 and <= %lu", (unsigned long)CBMaxPreKeyID] userInfo:nil];
    }
    if (range.length < 1 || range.length > CBMaxPreKeyID) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"length must be >= 1 and <=  %lu", (unsigned long)CBMaxPreKeyID] userInfo:nil];
    }
    
    __block NSArray *keys = nil;
    dispatch_sync(self.cryptoBoxQueue, ^{
        CBThrowIllegalStageExceptionIfClosed([self isClosedInternally]);
        
        NSMutableArray *newKeys = [NSMutableArray arrayWithCapacity:range.length];
        for (NSUInteger i = 0; i < range.length; ++i) {
            uint16_t newId = (range.location + i) % 0xFFFF;
            
            CBPreKey *preKey = [CBPreKey preKeyWithId:newId boxRef:self->_boxBacking error:error];
            if (*error != NULL || preKey == nil) {
                return;
            }
            [newKeys addObject:preKey];
        }
        
        keys = [NSArray arrayWithArray:newKeys];
    });
    
    return keys;
}

- (void)closeSession:(nonnull CBSession *)session
{
    dispatch_sync(self.cryptoBoxQueue, ^{
        if ([self isClosedInternally]) {
            return;
        }
        [session close];
        [self removeSession:session];
    });
}

- (void)closeAllSessions
{
    dispatch_sync(self.cryptoBoxQueue, ^{
        CBThrowIllegalStageExceptionIfClosed([self isClosedInternally]);
        
        [self closeAllSessionsInternally];
    });
}


- (void)close
{
    dispatch_sync(self.cryptoBoxQueue, ^{
        CBThrowIllegalStageExceptionIfClosed([self isClosedInternally]);
        
        [self closeAllSessionsInternally];
        [self closeInternally];
    });
}

- (BOOL)isClosed
{
    __block BOOL closed = NO;
    dispatch_sync(self.cryptoBoxQueue, ^{
        closed = [self isClosedInternally];
    });
    return closed;
}

- (void)rollbackSession:(CBSession *)session;
{
    dispatch_sync(self.cryptoBoxQueue, ^{
        [self removeSession:session];
    });
}

#pragma mark - Internal, not dispatch_sync protected methods

- (BOOL)isClosedInternally
{
    return (_boxBacking == NULL);
}

- (void)closeInternally
{
    cbox_close(_boxBacking);
    _boxBacking = NULL;
}

- (void)closeAllSessionsInternally
{
    if ([self isClosedInternally]) {
        return;
    }
    for (CBSession *session in self.sessions.allValues) {
        [session close];
    }
    [self removeAllSessions];
}

- (void)removeSession:(CBSession *)session;
{
    [self.sessions removeObjectForKey:session.sessionId];
    [self.sessionsRequiringSave removeObject:session];
}

- (void)removeAllSessions;
{
    [self.sessions removeAllObjects];
    [self.sessionsRequiringSave removeAllObjects];
}

@end



@implementation CBCryptoBox (Internal)

- (nonnull instancetype)initWithCBoxRef:(nonnull CBoxRef)box
{
    self = [super init];
    if (self) {
        _boxBacking = box;
        
        self.sessions = [NSMutableDictionary new];
        // TODO: Can we use here DISPATCH_QUEUE_CONCURRENT check
        self.cryptoBoxQueue = dispatch_queue_create("org.pkaboo.cryptobox.cryptoBoxQueue", DISPATCH_QUEUE_SERIAL);
        self.sessionsRequiringSave = [NSMutableSet set];
    }
    return self;
}

- (CBoxRef)box
{
    return _boxBacking;
}

@end
