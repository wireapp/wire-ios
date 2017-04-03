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


@import WireSystem;

#import "ZMPushChannelConnection.h"
#import "ZMPushChannelConnection+WebSocket.h"
#import "ZMWebSocket.h"
#import "ZMAccessToken.h"
#import "TransportTracing.h"
#import <libkern/OSAtomic.h>
#import "ZMTLogging.h"


static NSString* ZMLogTag = ZMT_LOG_TAG_PUSHCHANNEL;



@interface ZMPushChannelConnection ()
{
    int32_t _isClosed;
}

@property (nonatomic, weak) id<ZMPushChannelConsumer> consumer;
@property (nonatomic) id<ZMSGroupQueue> consumerQueue;
@property (nonatomic) ZMWebSocket *webSocket;
@property (nonatomic) dispatch_queue_t webSocketQueue;
@property (nonatomic) ZMSDispatchGroup *webSocketGroup;
@property (nonatomic) NSTimeInterval pingInterval;
@property (nonatomic) NSTimer *pingTimer;
@property (nonatomic) NSHTTPURLResponse *closeResponse;

@end






@implementation ZMPushChannelConnection

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"You should not use -init" userInfo:nil];
    return [self initWithURL:nil consumer:nil queue:nil accessToken:nil clientID:nil userAgentString:nil];
}

- (instancetype)initWithURL:(NSURL *)URL consumer:(id<ZMPushChannelConsumer>)consumer queue:(id<ZMSGroupQueue>)queue accessToken:(ZMAccessToken *)accessToken clientID:(NSString *)clientID userAgentString:(NSString *)userAgentString;
{
    return [self initWithURL:URL consumer:consumer queue:queue webSocket:nil accessToken:accessToken clientID:clientID userAgentString:userAgentString];
}

- (instancetype)initWithURL:(NSURL *)URL consumer:(id<ZMPushChannelConsumer>)consumer queue:(id<ZMSGroupQueue>)queue webSocket:(ZMWebSocket *)webSocket accessToken:(ZMAccessToken *)accessToken clientID:(NSString *)clientID userAgentString:(NSString *)userAgentString;
{
    VerifyReturnNil(consumer != nil);
    VerifyReturnNil(queue != nil);
    self = [super init];
    if (self != nil) {
        self.consumer = consumer;
        self.consumerQueue = queue;
        self.webSocketQueue = dispatch_queue_create("ZMPushChannel.websocket", 0);
        self.webSocketGroup = queue.dispatchGroup;
        
        if (URL != nil && clientID != nil) {
            NSURLComponents *components = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];
            components.queryItems = @[[NSURLQueryItem queryItemWithName:@"client" value:clientID]];
            URL = components.URL;
        }
        
        if (webSocket == nil) {
            NSMutableDictionary *headers = [accessToken.httpHeaders mutableCopy];
            if (0 < userAgentString.length) {
                headers[@"User-Agent"] = [userAgentString copy];
            }
            webSocket = [[ZMWebSocket alloc] initWithConsumer:self queue:self.webSocketQueue group:self.webSocketGroup url:URL additionalHeaderFields:headers];
            ZMTracePushChannelEvent(self, webSocket, 100);
        }
        self.webSocket = webSocket;
        self.pingInterval = 40;
    }
    return self;
}

- (BOOL)isOpen;
{
    return (_isClosed == 0);
}

- (void)checkConnection;
{
    [self.webSocketGroup asyncOnQueue:self.webSocketQueue block:^{
        [self.webSocket sendPingFrame];
    }];
}

- (void)close;
{
    // The compare & swap ensure that the code only runs if the values of isClosed was 0 and sets it to 1.
    // The check for 0 and setting it to 1 happen as a single atomic operation.
    if (OSAtomicCompareAndSwap32Barrier(0, 1, &_isClosed)) {
        
        ZMLogDebug(@"-[%@ %@]", self.class, NSStringFromSelector(_cmd));
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        id<ZMSGroupQueue> queue = self.consumerQueue;
        self.consumerQueue = nil;
        [self.webSocket close];
        id<ZMPushChannelConsumer> consumer = self.consumer;
        self.consumer = nil;
        ZMPushChannelConnection *channel = self;
        [self stopPingTimer];
        [queue performGroupedBlock:^{
            [consumer pushChannelDidClose:channel withResponse:self.closeResponse];
        }];
    }
}

- (void)dealloc;
{
    Require(_isClosed != 0);
}


- (void)setPingInterval:(NSTimeInterval)pingInterval
{
    [self.webSocketGroup asyncOnQueue:self.webSocketQueue block:^{
        self->_pingInterval = pingInterval;
        [self startPingTimer];
    }];
}

- (NSTimeInterval)shiftedPingInterval;
{
    double const shiftAmount = 0.1; // 10% shift
    double const shift = (2. * (arc4random() / (double) UINT32_MAX) - 1.) * shiftAmount;
    return self.pingInterval * (1. + shift);
}

- (void)startPingTimer;
{
    [self.pingTimer invalidate];
    NSTimeInterval const interval = self.shiftedPingInterval;
    ZMTracePushChannelPingStartStop(self, 0, (int) (interval * 1000.));
    NSTimer *timer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(sendPing:) userInfo:nil repeats:YES];
    timer.tolerance = interval * 0.1;
    self.pingTimer = timer;
    [self.webSocketGroup asyncOnQueue:dispatch_get_main_queue() block:^{
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        // Fire immediately to check if the socket is still alive after application resume
        [timer fire];
    }];
}

- (void)sendPing:(NSTimer *)timer
{
    NOT_USED(timer);
    ZMTracePushChannelPingFired(self);
    [self.webSocketGroup asyncOnQueue:self.webSocketQueue block:^{
        if (timer == self.pingTimer) {
            [self.webSocket sendPingFrame];
        }
    }];
}

- (void)stopPingTimer;
{
    ZMTracePushChannelPingStartStop(self, 1, 0);
    NSTimer *timer = self.pingTimer;
    self.pingTimer = nil;
    [self.webSocketGroup asyncOnQueue:dispatch_get_main_queue() block:^{
        [timer invalidate];
    }];
}

@end



@implementation ZMPushChannelConnection (ZMWebSocketConsumer)

-(void)webSocketDidCompleteHandshake:(ZMWebSocket *)websocket HTTPResponse:(NSHTTPURLResponse *)response
{
    ZMLogDebug(@"-[%@ %@]", self.class, NSStringFromSelector(_cmd));
    
    ZMTracePushChannelEvent(self, websocket, 0);
    [self.consumerQueue performGroupedBlock:^{
        [self.consumer pushChannelDidOpen:self withResponse:response];
    }];
}

- (void)webSocket:(ZMWebSocket *)webSocket didReceiveFrameWithText:(NSString *)text;
{
    ZMTracePushChannelEvent(self, webSocket, 1);
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    [self webSocket:webSocket didReceiveFrameWithData:data];
}

- (void)webSocket:(ZMWebSocket *)webSocket didReceiveFrameWithData:(NSData *)data;
{
    ZMTracePushChannelEvent(self, webSocket, 2);
    VerifyReturn(data != nil);
    NOT_USED(webSocket);
    NSError *error;
    id<ZMTransportData> transportData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (transportData == nil) {
        ZMLogError(@"Failed to parse data into JSON from push channel: %@", error);
    } else {
        [self.consumerQueue performGroupedBlock:^{
            [self.consumer pushChannel:self didReceiveTransportData:transportData];
        }];
    }
}

- (void)webSocketDidClose:(ZMWebSocket *)webSocket HTTPResponse:(NSHTTPURLResponse *)response;
{
    ZMTracePushChannelEvent(self, webSocket, 3);
    self.closeResponse = response;
    [self close];
}

@end
