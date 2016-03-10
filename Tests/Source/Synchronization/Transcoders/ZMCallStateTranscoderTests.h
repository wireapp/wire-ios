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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


@import ZMTransport;

#import "MessagingTest.h"
#import "ZMCallStateTranscoder.h"
#import "ZMConversation+Internal.h"
#import "ZMContextChangeTracker.h"
#import "ZMDownstreamObjectSync.h"
#import "ZMUser+Internal.h"

#import "ZMManagedObject+Internal.h"
#import "ZMUpdateEvent.h"
#import "ZMUpstreamModifiedObjectSync.h"
#import "ZMFlowSync.h"
#import "ZMObjectStrategyDirectory.h"
#import "ZMConnection+Internal.h"
#import "ZMVoiceChannel+Internal.h"
#import "ZMNotifications.h"
#import "ZMUpstreamTranscoder.h"
#import "ZMChangeTrackerBootstrap+Testing.h"
#import "ZMUpstreamModifiedObjectSync.h"
#import "ZMVoiceChannel+Testing.h"
#import "ZMUserSession+Internal.h"
#import "ZMOperationLoop.h"
#import "ZMGSMCallHandler.h"
#import <zmessaging/ZMUpstreamRequest.h>

@interface ZMCallStateTranscoderTests : MessagingTest

@property (nonatomic) ZMCallStateTranscoder<ZMDownstreamTranscoder, ZMUpstreamTranscoder> *sut;
@property (nonatomic) id objectStrategyDirectory;
@property (nonatomic) id flowTranscoder;
@property (nonatomic) ZMConversation *syncSelfToUser1Conversation;
@property (nonatomic) ZMConversation *syncSelfToUser2Conversation;
@property (nonatomic) ZMConversation *syncGroupConversation;
@property (nonatomic) ZMUser *syncSelfUser;
@property (nonatomic) ZMUser *syncOtherUser1;
@property (nonatomic) ZMUser *syncOtherUser2;
@property (nonatomic) NSSet *keys;
@property (nonatomic) id gsmCallHandler;

- (void)tearDownVoiceChannelForSyncConversation:(ZMConversation *)syncConversation;

@end