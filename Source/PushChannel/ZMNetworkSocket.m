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


@import CFNetwork;
@import Security;
#import "ZMNetworkSocket.h"
#import "ZMStreamPairThread.h"
#import "ZMDataBuffer.h"
#import "ZMServerTrust.h"
#import <libkern/OSAtomic.h>

NS_ENUM(int, Trace) {
    TraceClosingSocket = 100,
    TraceCreatedSocket = 101,
    TraceSocketEvent = 102,
    TraceNetworkSocketInit = 0,
    TraceNetworkSocketOpen = 2,
    TraceNetworkSocketClose = 1,
    TraceNetworkSocketReadData = 3,
    TraceNetworkSocketWroteData = 4,
};



@interface ZMNetworkSocket ()
{
    int32_t _isOpen;
    BOOL _didCheckTrust;
    BOOL _trusted;
}

@property (nonatomic) NSURL *URL;
@property (nonatomic, weak) id<ZMNetworkSocketDelegate> delegate;
@property (nonatomic) dispatch_queue_t delegateQueue;
@property (nonatomic) ZMSDispatchGroup *delegateGroup;
@property (nonatomic) dispatch_queue_t dataBufferIsolation;

@property (nonatomic) NSInputStream *inputStream;
@property (nonatomic) NSOutputStream *outputStream;
@property (nonatomic, readonly) BOOL usesSSL;
@property (nonatomic) ZMStreamPairThread *streamPairThread;
@property (nonatomic) ZMDataBuffer *dataBuffer;

@end



@interface ZMNetworkSocket (StreamDelegate) <NSStreamDelegate>
@end



@implementation ZMNetworkSocket

- (instancetype)initWithURL:(NSURL *)URL delegate:(id<ZMNetworkSocketDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue group:(ZMSDispatchGroup *)group;
{
    self = [super init];
    if (self) {
        self.URL = URL;
        self.delegate = delegate;
        self.delegateQueue = delegateQueue;
        self.delegateGroup = group;
        self.dataBuffer = [[ZMDataBuffer alloc] init];
        self.dataBufferIsolation = dispatch_queue_create("ZMNetworkSocket.outputStream", 0);
    }
    return self;
}

- (void)close;
{
    // The compare & swap ensure that the code only runs if the values of isClosed was 0 and sets it to 1.
    // The check for 0 and setting it to 1 happen as a single atomic operation.
    if (OSAtomicCompareAndSwap32Barrier(1, 0, &_isOpen)) {
        [self.streamPairThread cancel];
        self.inputStream.delegate = nil;
        self.outputStream.delegate = nil;
        [self.delegateGroup asyncOnQueue:self.dataBufferIsolation block:^{
            self.dataBuffer = nil;
        }];
        [self.delegateGroup asyncOnQueue:self.delegateQueue block:^{
            [self.inputStream close];
            [self.outputStream close];
            [self.delegate networkSocketDidClose:self];
            self.delegate = nil;
        }];
    }
}

- (void)dealloc
{
    RequireString(! _isOpen, "Still open during call to dealloc.");
}

- (void)open;
{
    RequireString(OSAtomicCompareAndSwap32Barrier(0, 1, &_isOpen),
                  "Trying to open %p multiple times.", (__bridge void *) self);
    
    [self createStreamPair];
    [self configureStreamPairs];
    [self.inputStream open];
    [self.outputStream open];
}

- (void)createStreamPair;
{
    VerifyReturn(self.URL.host != nil);
    
    NSString * const hostName = self.URL.host;
    int32_t const port = (self.URL.port == nil) ? (self.usesSSL ? 443 : 80) : self.URL.port.intValue;
    
    _Pragma("clang diagnostic push")
    _Pragma("clang diagnostic ignored \"-Wselector\"")
    SEL const selector = @selector(getStreamsToHostWithName:port:inputStream:outputStream:);
    _Pragma("clang diagnostic pop")
    
    if ([NSStream respondsToSelector:selector]) {
        NSInputStream *is;
        NSOutputStream *os;
        [NSStream getStreamsToHostWithName:hostName port:port inputStream:&is outputStream:&os];
        self.inputStream = is;
        self.outputStream = os;
    } else {
        CFHostRef host = CFHostCreateWithName(NULL, (__bridge CFStringRef) hostName);
        if (host == NULL) {
            return;
        }
        CFReadStreamRef readStream = NULL;
        CFWriteStreamRef writeStream = NULL;
        CFStreamCreatePairWithSocketToCFHost(NULL, host, port, &readStream, &writeStream);
        CFRelease(host);
        
        self.inputStream = CFBridgingRelease(readStream);
        self.outputStream = CFBridgingRelease(writeStream);
    }

    VerifyString(self.inputStream != nil, "Failed to create input stream.");
    VerifyString(self.outputStream != nil, "Failed to create output stream.");
}

- (void)configureStreamPairs;
{
    self.inputStream.delegate = self;
    self.outputStream.delegate = self;
    
    [self startRunLoop];
    
    if (self.usesSSL) {
        // Verify server certificate https://wearezeta.atlassian.net/browse/MEC-78
        
        NSDictionary *sslSettings =
        @{(__bridge id) kCFStreamSSLPeerName: self.URL.host,
          (__bridge id) kCFStreamSSLValidatesCertificateChain: @NO};
        
        [self.inputStream setProperty:sslSettings forKey:(__bridge id) kCFStreamPropertySSLSettings];
        [self.outputStream setProperty:sslSettings forKey:(__bridge id) kCFStreamPropertySSLSettings];
        
        [self.inputStream setProperty:NSStreamSocketSecurityLevelTLSv1 forKey:NSStreamSocketSecurityLevelKey];
        [self.outputStream setProperty:NSStreamSocketSecurityLevelTLSv1 forKey:NSStreamSocketSecurityLevelKey];
    }
    
    [self.inputStream setProperty:NSStreamNetworkServiceTypeBackground forKey:NSStreamNetworkServiceType];
    [self.outputStream setProperty:NSStreamNetworkServiceTypeBackground forKey:NSStreamNetworkServiceType];
}

- (void)startRunLoop;
{
    self.streamPairThread = [[ZMStreamPairThread alloc] initWithInputStream:self.inputStream outputStream:self.outputStream];
    [self.streamPairThread start];
}

- (BOOL)usesSSL;
{
    NSString *scheme = self.URL.scheme;
    return ([scheme isEqualToString:@"https"] ||
            [scheme isEqualToString:@"wss"]);
}

- (void)didReadDataFromNetwork:(dispatch_data_t)data;
{
    [self.delegateGroup asyncOnQueue:self.delegateQueue block:^{
        [self.delegate networkSocket:self didReceiveData:data];
    }];
}

- (void)writeToOutputStream;
{
    // This must only be called on the streamPairThread,
    // e.g. from within the -stream:handleEvent: callback
    dispatch_sync(self.dataBufferIsolation, ^{
        dispatch_data_t data = [self.dataBuffer data];
        if (data != nil) {
            __block size_t numberOfBytesWritten = 0;
            dispatch_data_apply(data, ^bool(dispatch_data_t region, size_t offset, const void *buffer, size_t size) {
                NOT_USED(region);
                NOT_USED(offset);
                size_t const count = (size_t) [self.outputStream write:buffer maxLength:size];
                numberOfBytesWritten += count;
                BOOL const stop = (count != size);
                return ! stop;
            });
            [self.dataBuffer clearUntilOffset:numberOfBytesWritten];
        }
    });
}

- (void)writeDataToNetwork:(dispatch_data_t)data;
{
    [self.delegateGroup asyncOnQueue:self.delegateQueue block:^{
        [self appendDataToOutputBuffer:data];
    }];
}

- (void)appendDataToOutputBuffer:(dispatch_data_t)data;
{
    // If the buffer was empty, we always try to write.
    // It seems like -hasSpaceAvailable is not entirely reliable in those situations.
    dispatch_async(self.dataBufferIsolation, ^(){
        [self.dataBuffer addData:data];
        // Switch onto the streams' thread:
        [self performSelector:@selector(writeToOutputStream) onThread:self.streamPairThread withObject:nil waitUntilDone:NO];
    });
}

@end



@implementation ZMNetworkSocket (StreamDelegate)

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode;
{
    if ((eventCode & NSStreamEventOpenCompleted) != NSStreamEventNone) {
        if (aStream == self.outputStream) {
            [self.delegateGroup asyncOnQueue:self.delegateQueue block:^{
                [self.delegate networkSocketDidOpen:self];
            }];
        }
    }
    if ((eventCode & NSStreamEventHasBytesAvailable) != NSStreamEventNone) {
        if (checkTrust(self, aStream)) {
            [self bytesAvailableInStream:aStream];
        }
    }
    if ((eventCode & NSStreamEventHasSpaceAvailable) != NSStreamEventNone) {
        if (checkTrust(self, aStream)) {
            [self spaceAvailableInStream:aStream];
        }
    }
    if ((eventCode & NSStreamEventErrorOccurred) != NSStreamEventNone) {
        [self close];
    }
    if ((eventCode & NSStreamEventEndEncountered) != NSStreamEventNone) {
        [self close];
    }
}

static BOOL checkTrust(ZMNetworkSocket * const socket, NSStream * const stream) ZM_MUST_USE_RETURN;
static BOOL checkTrust(ZMNetworkSocket * const socket, NSStream * const stream)
{
    if (socket->_didCheckTrust) {
        return socket->_trusted;
    }
    socket->_didCheckTrust = YES;
    id peerTrust = [stream propertyForKey:(__bridge id) kCFStreamPropertySSLPeerTrust];
    socket->_trusted = verifyServerTrust((__bridge SecTrustRef)peerTrust, socket.URL.host);
    if (! socket->_trusted) {
        [socket close];
    }
    return socket->_trusted;
}

- (void)bytesAvailableInStream:(NSStream *)aStream;
{
    if (self.inputStream == aStream) {
        uint8_t buffer[4 * 1024];
        NSInteger const count = [self.inputStream read:buffer maxLength:sizeof(buffer)];
        if (0 < count) {
            dispatch_data_t data = dispatch_data_create(buffer, (size_t) count, NULL, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
            [self didReadDataFromNetwork:data];
        }
    }
}

- (void)spaceAvailableInStream:(NSStream *)aStream;
{
    if (self.outputStream == aStream) {
        [self writeToOutputStream];
    }
}

@end
