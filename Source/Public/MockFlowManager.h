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

@class MockTransportSession;
@class MockConversation;
@class MockUser;
@class UIView;

@protocol AVSFlowManagerDelegate;



/// Implements the same interface as the AVSFlowManager and records calls in order to later verify them.
@interface MockFlowManager : NSObject

- (instancetype)initWithMockTransportSession:(MockTransportSession *)mockTransportSession;
- (void)appendLogForConversation:(NSString *)convid message:(NSString *)msg;
- (NSArray *)AVSlogMessagesForConversationID:(NSString *)conversationID;
+ (NSComparator)conferenceComparator;
- (void)addUser:(NSString *)convId userId:(NSString *)userId name:(NSString *)name;
- (void)setSelfUser:(NSString *)userId;
- (void)refreshAccessToken:(NSString *)token type:(NSString *)type;


@property (nonatomic, readonly) NSArray *aquiredFlows;
@property (nonatomic, readonly) NSArray *releasedFlows;
@property (nonatomic, readonly) NSString *selfUserID;
@property (nonatomic, readonly) NSString *accessToken;
@property (nonatomic, readonly) NSArray *joinedUsers;

@property (nonatomic, weak) id<AVSFlowManagerDelegate> delegate;

@end


/// This duplicates AVSFlowManager
@interface MockFlowManager (Fake)

- (BOOL)acquireFlows:(NSString *)convId;
- (void)releaseFlows:(NSString *)convId;

@end



@interface MockFlowManager (VideoCalling)


- (BOOL)isMediaEstablishedInConversation:(NSString *)convId;
- (BOOL)canSendVideoForConversation:(NSString *)convId;
- (BOOL)isSendingVideoInConversation:(NSString *)convId
                      forParticipant:(NSString *)partId;
- (void)setVideoSendState:(int)state forConversation:(NSString *)convId;

- (void)setVideoSendActive:(BOOL __unused)active forConversation:(NSString * __unused)conversationId;
- (void)setVideoPreview:(UIView * __unused)view forConversation:(NSString * __unused)conversationId;
- (void)setVideoView:(UIView * __unused)view forConversation:(NSString * __unused)conversationId forParticipant:(NSString * __unused)partId;
- (void)setVideoCaptureDevice:(NSString * __unused)deviceId forConversation:(NSString * __unused)conversationId;


- (void)simulateCanSendVideoInConversation:(MockConversation *)conv;
- (void)simulateMediaIsEstablishedInConversation:(MockConversation*)conv;
- (void)simulateOther:(MockUser *)otherUser isSendingVideo:(BOOL)isSendingVideo conv:(MockConversation *)conv;

- (void)resetVideoCalling;

@end
