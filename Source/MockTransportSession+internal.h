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


#import "MockTransportSession.h"

@class ZMTransportRequest;
@class MockPushEvent;

@interface TestTransportSessionRequest : NSObject

@property (nonatomic) ZMTransportRequest *embeddedRequest;

@property (nonatomic, readonly) NSURL *URL;
@property (nonatomic, copy) NSDictionary *query;
@property (nonatomic, readonly) ZMTransportRequestMethod method;
@property (nonatomic, copy, readonly) id <ZMTransportData> payload;

@property (nonatomic, copy) NSArray *pathComponents;
@property (nonatomic, readonly, copy) NSString *binaryDataTypeAsMIME;

@end



@interface MockTransportSession (Internal)

@property (nonatomic, readonly) NSMutableArray<MockPushEvent *>* generatedPushEvents;
@property (nonatomic) MockUser* selfUser;

- (MockConversation *)fetchConversationWithIdentifier:(NSString *)conversationID;
- (MockUser *)fetchUserWithIdentifier:(NSString *)userID;
- (MockConnection *)fetchConnectionFrom:(MockUser *)userID to:(MockUser *)otherUserID;
- (void)addPushToken:(NSDictionary *)pushToken;
- (ZMTransportResponse *)errorResponseWithCode:(NSInteger)code reason:(NSString *)reason;
- (MockEvent *)eventIfNeededByUser:(MockUser *)byUser type:(ZMTUpdateEventType)type data:(id<ZMTransportData>)data;

- (MockConnection *)connectionFromUserIdentifier:(NSString *)fromUserIdentifier toUserIdentifier:(NSString *)toUserIdentifier;

@property (nonatomic, readonly) NSMutableSet *whitelistedEmails;
@property (nonatomic, readonly) NSMutableSet *phoneNumbersWaitingForVerificationForRegistration;
@property (nonatomic, readonly) NSMutableSet *phoneNumbersWaitingForVerificationForLogin;
@property (nonatomic, readonly) NSMutableSet *phoneNumbersWaitingForVerificationForProfile;
@property (atomic, weak, readonly) id<ZMPushChannelConsumer> pushChannelConsumer;


@end



@interface MockTransportSession (MockTransportSessionObjectCreation) <MockTransportSessionObjectCreation>
@end
