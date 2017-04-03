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
#import "TransportTracing.h"
#import "ZMTLogging.h"

static NSString* ZMLogTag ZM_UNUSED = ZMT_LOG_TAG_PUSHCHANNEL;

NS_ENUM(int, PushChannelTrace) {
    PushChannelTraceCreateNew = 0,
    PushChannelTraceCreateNewRequestNewTokenFirst = 1,
    PushChannelTraceClosingAndRemovingConsumer = 2,
    PushChannelTraceClosing = 3,
    PushChannelTraceOpenIfClosed = 4,
    
    PushChannelTraceCreatingNewPushChannel = 10,
    PushChannelTraceConsumerOrGroupInvalid = 11,
    PushChannelTraceIsAlreadyCreating = 12,
    PushChannelTraceCreatingInstance = 13,
    PushChannelTraceCreatingNow = 14,
    PushChannelTraceCreatingWithBackoff = 15,
    PushChannelTraceBackoffExpired = 16,
};

NS_ENUM(int, TraceEvent) {
    TraceEventDidReceiveData = 0,
    TraceEventDidOpen = 1,
    TraceEventDidClose = 2,
};



@interface ZMTransportPushChannel ()

@property (nonatomic) ZMTransportRequestScheduler *scheduler;
@property (nonatomic) Class pushChannelClass;
@property (nonatomic) NSURL *url;
@property (nonatomic) NSString *userAgentString;
@property (nonatomic, weak) id<ZMPushChannelConsumer>  consumer;
@property (nonatomic) id<ZMSGroupQueue> groupQueue;
@property (nonatomic) ZMPushChannelConnection *pushChannel;
@property (nonatomic) BOOL isUsingMobileNetwork;

@end



@interface ZMTransportPushChannel (Consumer) <ZMPushChannelConsumer>
@end



@implementation ZMTransportPushChannel

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

- (void)setPushChannelConsumer:(id<ZMPushChannelConsumer>)consumer groupQueue:(id<ZMSGroupQueue>)groupQueue;
{
    ZMLogInfo(@"Setting push channel consumer");
    if (consumer != nil) {
        Require(groupQueue != nil);
        self.groupQueue = groupQueue;
        self.consumer = consumer;
        [self scheduleOpenPushChannel];
    } else {
        [self closeAndRemoveConsumer];
    }
}

- (void)scheduleOpenPushChannel;
{
    ZMOpenPushChannelRequest *openPushChannelItem = [[ZMOpenPushChannelRequest alloc] init];
    ZMTransportRequestScheduler *scheduler = self.scheduler;
    [scheduler performGroupedBlock:^{
        [scheduler addItem:openPushChannelItem];
    }];
}

- (void)createPushChannelWithAccessToken:(ZMAccessToken *)accessToken clientID:(NSString *)clientID;
{
    ZMTraceTransportSessionPushChannel(PushChannelTraceOpenIfClosed, self.pushChannel, (int) self.pushChannel.isOpen);
    id<ZMPushChannelConsumer> consumer = self.consumer;
    if (consumer != nil){
        if (self.pushChannel.isOpen) {
            ZMTraceTransportSessionPushChannel(PushChannelTraceCreatingNewPushChannel, nil, 1);
        } else {
            self.pushChannel = [[self.pushChannelClass alloc] initWithURL:self.url consumer:self queue:self.groupQueue accessToken:accessToken clientID:clientID userAgentString:self.userAgentString];
            
            ZMTraceTransportSessionPushChannel(PushChannelTraceCreatingInstance, self.pushChannel, 0);
            ZMLogInfo(@"Opening push channel");
        }
    }
    else {
        ZMTraceTransportSessionPushChannel(PushChannelTraceConsumerOrGroupInvalid, nil, 0);
    }
}

- (void)closeAndRemoveConsumer;
{
    ZMTraceTransportSessionPushChannel(PushChannelTraceClosingAndRemovingConsumer, nil, 0);
    ZMLogInfo(@"Remove push channel consumer");
    self.consumer = nil;
    self.groupQueue = nil;
    [self.pushChannel close];
}

- (void)close;
{
    ZMTraceTransportSessionPushChannel(PushChannelTraceClosing, nil, 0);
    ZMLogInfo(@"close");
    [self.pushChannel close];
}

- (void)reachabilityDidChange:(ZMReachability *)reachability;
{
    BOOL oldIsUsingMobileNetwork = self.isUsingMobileNetwork;
    self.isUsingMobileNetwork = reachability.isMobileConnection;
    
    if (oldIsUsingMobileNetwork && !self.isUsingMobileNetwork) {
        [self.pushChannel close];
    } else {
        [self.pushChannel checkConnection];
    }
}

@end



@implementation ZMTransportPushChannel (Consumer)

- (void)pushChannel:(ZMPushChannelConnection *)channel didReceiveTransportData:(id<ZMTransportData>)data;
{
    ZMTraceTransportSessionPushChannelEvent(TraceEventDidReceiveData, channel, 0);
    ZMLogInfo(@"[PushChannel] Received payload on push channel.");

    [self.networkStateDelegate didReceiveData];
    [self.consumer pushChannel:channel didReceiveTransportData:data];
}

- (void)pushChannelDidClose:(ZMPushChannelConnection *)channel withResponse:(NSHTTPURLResponse *)response;
{
    ZMTraceTransportSessionPushChannelEvent(TraceEventDidClose, channel, (int) response.statusCode);
    ZMLogInfo(@"[PushChannel] Push channel did close.");

    id<ZMPushChannelConsumer> consumer = self.consumer;
    if (consumer != nil) {
        [self scheduleOpenPushChannel];
    }
    [consumer pushChannelDidClose:channel withResponse:response];
    
    if (response != nil) {
        ZMTransportRequestScheduler *scheduler = self.scheduler;
        [scheduler performGroupedBlock:^{
            [scheduler processCompletedURLResponse:response URLError:nil];
        }];
    }
}

- (void)pushChannelDidOpen:(ZMPushChannelConnection *)channel withResponse:(NSHTTPURLResponse *)response;
{
    ZMTraceTransportSessionPushChannelEvent(TraceEventDidOpen, channel, (int) response.statusCode);
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
