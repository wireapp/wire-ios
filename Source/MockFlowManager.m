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


@import WireTransport;
@import WireUtilities;

#import "MockFlowManager.h"
#import "MockTransportSession+internal.h"
#import <WireMockTransport/WireMockTransport-Swift.h>


@interface MockFlowManager ()

@property (nonatomic, weak) MockTransportSession *mockTransportSession;
@property (nonatomic, readonly) NSMutableArray *mutableAquiredFlows;
@property (nonatomic, readonly) NSMutableArray *mutableReleasedFlows;
@property (nonatomic, readonly) NSMutableDictionary *mutableAVSLogMessages;
@property (nonatomic) NSString *selfUserID;
@property (nonatomic) NSString *accessToken;
@property (nonatomic) NSMutableArray *internalJoinedUsers;

@property (nonatomic) NSString *convThatCanSendVideo;
@property (nonatomic) NSString *convWithMediaEstablished;
@property (nonatomic) NSMutableArray *usersSendingVideo;

@end



@implementation MockFlowManager

- (instancetype)initWithMockTransportSession:(MockTransportSession *)mockTransportSession;
{
    self = [super init];
    if (self) {
        self.mockTransportSession = mockTransportSession;
        _mutableAquiredFlows = [NSMutableArray array];
        _mutableReleasedFlows = [NSMutableArray array];
        _mutableAVSLogMessages = [NSMutableDictionary dictionary];
        self.internalJoinedUsers = [NSMutableArray array];
        self.usersSendingVideo = [NSMutableArray array];
    }
    return self;
}

- (NSArray *)aquiredFlows;
{
    return [self.mutableAquiredFlows copy];
}

- (NSArray *)releasedFlows;
{
    return [self.mutableReleasedFlows copy];
}

- (NSArray *)AVSlogMessagesForConversationID:(NSString *)conversationID
{
    NSMutableArray *messages = self.mutableAVSLogMessages[conversationID];
    return [messages copy];
}

- (void)appendLogForConversation:(NSString *)convid message:(NSString *)msg
{
    if (msg == nil || convid == nil) {
        return;
    }
    
    NSMutableArray *previousMessages = self.mutableAVSLogMessages[convid] ?: [NSMutableArray array];
    [previousMessages addObject:msg];
    self.mutableAVSLogMessages[convid] = previousMessages;
}

+ (NSComparator)conferenceComparator
{
    return ^NSComparisonResult(NSString* obj1, NSString* obj2) {
        return [obj1 compare:obj2];
    };
}

- (NSArray *)joinedUsers
{
    return [self.internalJoinedUsers copy];
}

- (void)addUser:(NSString *)convId userId:(NSString *)userId name:(NSString *)name
{
    NOT_USED(convId);
    NOT_USED(name);
    [self.internalJoinedUsers addObject:userId];
}

- (void)setSelfUser:(NSString *)userId
{
    self.selfUserID = userId;
}

- (void)refreshAccessToken:(NSString *)token type:(NSString *)type
{
    NOT_USED(type);
    self.accessToken = token;
}

@end



@implementation MockFlowManager (Fake)

- (NSArray *)events;
{
    return @[];
}

- (void)processResponseWithStatus:(int)status
                           reason:(NSString *)reason
                        mediaType:(NSString *)mtype
                          content:(NSData *)content
                          context:(void const *)ctx;
{
    NOT_USED(status);
    NOT_USED(reason);
    NOT_USED(mtype);
    NOT_USED(content);
    NOT_USED(ctx);
}

- (BOOL)processEventWithMediaType:(NSString *)mtype
                          content:(NSData *)content;
{
    NOT_USED(mtype);
    NOT_USED(content);
    return YES;
}

- (BOOL)acquireFlows:(NSString *)convId;
{
    Require(convId != nil);
    [self.mutableAquiredFlows addObject:convId];
    return YES;
}

- (void)releaseFlows:(NSString *)convId;
{
    [self.mutableReleasedFlows addObject:convId];
}


- (void)networkChanged;
{
}

- (id)mediaDelegate;
{
    return nil;
}

- (void)setEnableLogging:(BOOL)enable;
{
    NOT_USED(enable);
}

- (void)setEnableMetrics:(BOOL)enable;
{
    NOT_USED(enable);
}

- (void)setSessionId:(NSString *)sessId forConversation:(NSString *)convId;
{
    NOT_USED(sessId);
    NOT_USED(convId);
}

@end




@implementation MockFlowManager (VideoCalling)

- (BOOL)isMediaEstablishedInConversation:(NSString *)convId;
{
    return [self.convWithMediaEstablished isEqualToString:convId];
}

- (BOOL)canSendVideoForConversation:(NSString *)convId;
{
    return [self.convThatCanSendVideo isEqualToString:convId];
}

- (BOOL)isSendingVideoInConversation:(NSString *)convId
                      forParticipant:(NSString *)partId;
{
    NOT_USED(convId);
    return [self.usersSendingVideo containsObject:partId];
}

- (void)setVideoSendState:(int)state forConversation:(NSString *)convId;
{
    NOT_USED(convId);
    MockTransportSession *session = self.mockTransportSession;
    if (state == 0) {
        session.selfUser.isSendingVideo = NO;
        [self.usersSendingVideo removeObject:self.selfUserID];
    } else {
        session.selfUser.isSendingVideo = YES;
        [self.usersSendingVideo addObject:self.selfUserID];
    }
}

- (void)setVideoSendActive:(BOOL __unused)active forConversation:(NSString * __unused)conversationId
{
    // no-op    
}

- (void)setVideoPreview:(UIView * __unused)view forConversation:(NSString * __unused)conversationId
{
    // no-op
}

- (void)setVideoView:(UIView * __unused)view forConversation:(NSString * __unused)conversationId forParticipant:(NSString * __unused)partId
{
    // no-op
}

- (void)setVideoCaptureDevice:(NSString * __unused)deviceId forConversation:(NSString * __unused)conversationId
{
    // no-op
}

- (void)simulateCanSendVideoInConversation:(MockConversation *)conv
{
    self.convThatCanSendVideo = conv.identifier;
}

- (void)simulateMediaIsEstablishedInConversation:(MockConversation*)conv
{
    self.convWithMediaEstablished = conv.identifier;
}

- (void)simulateOther:(MockUser *)otherUser isSendingVideo:(BOOL)isSendingVideo conv:(MockConversation *)conv
{
    if (otherUser == nil) {
        return;
    }
    if (isSendingVideo) {
        otherUser.isSendingVideo = YES;
        [self.usersSendingVideo addObject:otherUser.identifier];
    } else {
        otherUser.isSendingVideo = NO;
        [self.usersSendingVideo removeObject:otherUser.identifier];
    }
    self.convWithMediaEstablished = conv.identifier;
    self.convThatCanSendVideo = conv.identifier;
    [self.mockTransportSession saveAndCreatePushChannelEventForSelfUser];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FlowManagerCreatePreviewNotification" object:nil];
}

- (void)resetVideoCalling
{
    self.usersSendingVideo = [NSMutableArray array];
    self.convThatCanSendVideo = nil;
    self.convWithMediaEstablished = nil;
}


@end


