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


#import "ZMTransportPushChannel.h"

@import WireSystem;
#import "ZMTransportRequestScheduler.h"
#import "ZMTransportSession+internal.h"
#import "ZMPushChannelConnection.h"
#import "ZMTLogging.h"

static NSString* ZMLogTag ZM_UNUSED = ZMT_LOG_TAG_PUSHCHANNEL;

@interface ZMTransportPushChannel ()

@property (nonatomic) ZMTransportRequestScheduler *scheduler;
@property (nonatomic) Class pushChannelClass;
@property (nonatomic) NSURL *url;
@property (nonatomic) NSString *userAgentString;
@property (nonatomic, weak) id<ZMPushChannelConsumer>  consumer;
@property (nonatomic, weak) id<ZMSGroupQueue> groupQueue;
@property (nonatomic) ZMPushChannelConnection *pushChannel;
@property (nonatomic, readonly) BOOL shouldBeOpen;

@end



@interface ZMTransportPushChannel (Consumer) <ZMPushChannelConsumer>
@end



@implementation ZMTransportPushChannel

@synthesize clientID = _clientID;
@synthesize keepOpen = _keepOpen;

- (void)setClientID:(NSString *)clientID
{
    _clientID = [clientID copy];
    
    [self.pushChannel close];
    [self attemptToOpen];
}

- (void)setAccessToken:(ZMAccessToken *)accessToken
{
    _accessToken = accessToken;
    
    [self.pushChannel close];
    [self attemptToOpen];
}

- (void)setKeepOpen:(BOOL)keepOpen
{
    _keepOpen = keepOpen;
    
    [self closeIfNotAllowedToBeOpen];
    [self attemptToOpen];
}


ZM_EMPTY_ASSERTING_INIT();

- (instancetype)initWithScheduler:(ZMTransportRequestScheduler *)scheduler userAgentString:(NSString *)userAgentString URL:(NSURL *)URL;
{
    return [self initWithScheduler:scheduler userAgentString:userAgentString URL:URL pushChannelClass:nil];
}

- (instancetype)initWithScheduler:(ZMTransportRequestScheduler *)scheduler userAgentString:(NSString *)userAgentString URL:(NSURL *)URL pushChannelClass:(Class)pushChannelClass;
{
    self = [super init];
    if (self) {
        self.scheduler = scheduler;
        self.url = [URL URLByAppendingPathComponent:@"/await"];
        self.userAgentString = userAgentString;
        self.pushChannelClass = pushChannelClass ?: ZMPushChannelConnection.class;
    }
    return self;
}

- (void)dealloc {
    [self.pushChannel close];
    self.pushChannel = nil;
    [self.scheduler tearDown];
}

- (void)setPushChannelConsumer:(id<ZMPushChannelConsumer>)consumer groupQueue:(id<ZMSGroupQueue>)groupQueue;
{
    ZMLogInfo(@"Setting push channel consumer");
    if (consumer != nil) {
        Require(groupQueue != nil);
        self.groupQueue = groupQueue;
        self.consumer = consumer;
        [self attemptToOpen];
    } else {
        [self closeAndRemoveConsumer];
    }
}

- (void)closeAndRemoveConsumer;
{
    ZMLogInfo(@"Remove push channel consumer");
    self.consumer = nil;
    self.groupQueue = nil;
    [self.pushChannel close];
}

- (void)close;
{
    ZMLogInfo(@"close");
    [self.pushChannel close];
}

- (void)attemptToOpen
{
    if (self.shouldBeOpen) {
        ZMOpenPushChannelRequest *openPushChannelItem = [[ZMOpenPushChannelRequest alloc] init];
        ZMTransportRequestScheduler *scheduler = self.scheduler;
        [scheduler performGroupedBlock:^{
            [scheduler addItem:openPushChannelItem];
        }];
    }
}

- (void)closeIfNotAllowedToBeOpen
{
    if (self.pushChannel.isOpen && !self.shouldBeOpen) {
        [self.pushChannel close];
    }
}

- (BOOL)shouldBeOpen
{
    return self.clientID != nil && self.accessToken != nil && self.consumer != nil && self.keepOpen && self.scheduler.reachability.mayBeReachable;
}

- (void)establishConnection
{
    if (!self.pushChannel.isOpen && self.shouldBeOpen) {
        self.pushChannel = [[self.pushChannelClass alloc] initWithURL:self.url consumer:self queue:self.groupQueue accessToken:self.accessToken clientID:self.clientID userAgentString:self.userAgentString];
        
        ZMLogInfo(@"Opening push channel");
    }
}

- (void)reachabilityDidChange:(ZMReachability *)reachability;
{
    BOOL didEnterWifi = !reachability.isMobileConnection && reachability.oldIsMobileConnection;
    BOOL didGoOnline = reachability.mayBeReachable && !reachability.oldMayBeReachable;
    
    if (didEnterWifi) {
        [self.pushChannel close];
    } else if (self.pushChannel.isOpen) {
        if (didGoOnline && !self.pushChannel.didCompleteHandshake) {
            // If we regain internet access after the handshake frame has been sent, but before the channel is closed, we have an improperly working channel
            // We need to close this one and open a new one (when `pushChannelDidClose:withResponse:` is called)
            [self.pushChannel close];
        } else {
            [self.pushChannel checkConnection];
        }
    }
}

@end



@implementation ZMTransportPushChannel (Consumer)

- (void)pushChannel:(ZMPushChannelConnection *)channel didReceiveTransportData:(id<ZMTransportData>)data;
{
    ZMLogInfo(@"[PushChannel] Received payload on push channel.");

    [self.networkStateDelegate didReceiveData];
    [self.consumer pushChannel:channel didReceiveTransportData:data];
}

- (void)pushChannelDidClose:(ZMPushChannelConnection *)channel withResponse:(NSHTTPURLResponse *)response;
{
    ZMLogInfo(@"[PushChannel] Push channel did close.");

    // Immediately try to re-open the push channel
    [self attemptToOpen];
    [self.consumer pushChannelDidClose:channel withResponse:response];
    
    if (response != nil) {
        ZMTransportRequestScheduler *scheduler = self.scheduler;
        [scheduler performGroupedBlock:^{
            [scheduler processCompletedURLResponse:response URLError:nil];
        }];
    }
    
    if (channel == self.pushChannel) {
        self.pushChannel = nil;
    }
}

- (void)pushChannelDidOpen:(ZMPushChannelConnection *)channel withResponse:(NSHTTPURLResponse *)response;
{
    ZMLogInfo(@"[PushChannel] Push channel did open.");

    [self.consumer pushChannelDidOpen:channel withResponse:response];
    if (response != nil) {
        ZMTransportRequestScheduler *scheduler = self.scheduler;
        [scheduler performGroupedBlock:^{
            [scheduler processCompletedURLResponse:response URLError:nil];
        }];
    }
}

@end
