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


@import CoreData;
@import WireTransport;

#import "MockConnection.h"
#import "MockConversation.h"
#import "MockPicture.h"
#import "MockEvent.h"
#import "MockAsset.h"
#import "MockPersonalInvitation.h"

@class MockFlowManager;
@class MockPushEvent;

@protocol MockTransportSessionObjectCreation;

NS_ASSUME_NONNULL_BEGIN

typedef ZMTransportResponse * _Nullable (^ZMCustomResponseGeneratorBlock)(ZMTransportRequest * _Nonnull request);

@interface MockTransportSession : NSObject <ZMRequestCancellation>

- (instancetype)initWithDispatchGroup:(nullable ZMSDispatchGroup *)group NS_DESIGNATED_INITIALIZER;

/// This will simply return @c self, but typecast to the expected type. For convenience.
- (ZMTransportSession *)mockedTransportSession;

@property (nonatomic, readonly) id<ZMPushChannel> pushChannel;

@property (nonatomic) NSURL *baseURL;
@property (nonatomic) NSURL *websocketURL;

@property (nonatomic) NSString *clientID;
@property (nonatomic) ZMPersistentCookieStorage *cookieStorage;
@property (readonly, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly, copy) ZMCompletionHandlerBlock accessTokenFailureHandler;
@property (nonatomic, readonly, copy) ZMAccessTokenHandlerBlock accessTokenSuccessHandler;

@property (nonatomic, readonly) MockUser* selfUser;
@property (nonatomic, readonly) BOOL isPushChannelActive;
@property (nonatomic, copy, nullable) ZMCustomResponseGeneratorBlock responseGeneratorBlock;
@property (nonatomic, readonly) NSArray *pushTokens;
@property (nonatomic) BOOL disableEnqueueRequests;

@property (nonatomic) BOOL doNotRespondToRequests; //to simulate offline

@property (nonatomic) NSUInteger maxMembersForGroupCall;
@property (nonatomic) NSUInteger maxCallParticipants;

@property (nonatomic, readonly) NSArray *updateEvents;

+ (NSString *)binaryDataTypeAsMIME:(NSString *)type;

- (BOOL)waitForAllRequestsToCompleteWithTimeout:(NSTimeInterval)timeout;

/// A list on transport requests received by client
- (NSArray<ZMTransportRequest *> *)receivedRequests;
/// Resets the list of received requests
- (void)resetReceivedRequests;

- (void)expireAllBlockedRequests;
- (void)tearDown;
- (void)completeAllBlockedRequests;

- (void)completePreviouslySuspendendRequest:(ZMTransportRequest *)request;

- (void)registerPushEvent:(MockPushEvent *)mockPushEvent;
- (void)logoutSelfUser;

@end



@interface MockTransportSession (CreatingObjects)

/// Runs the given @c block on the context's queue and saves the context.
- (void)performRemoteChanges:(void(^)(id<MockTransportSessionObjectCreation>))block;

- (void)saveAndCreatePushChannelEvents;
- (void)saveAndCreatePushChannelEventForSelfUser;

@end



@protocol MockTransportSessionObjectCreation <NSObject, ZMRequestCancellation>

- (MockUser *)insertSelfUserWithName:(NSString *)name;
- (MockUser *)insertUserWithName:(NSString *)name;
- (MockUser *)insertUserWithName:(NSString *)name includeClient:(BOOL)shouldIncludeClient;
- (NSDictionary<NSString *, MockPicture *> *)addProfilePictureToUser:(MockUser *)user;
- (NSDictionary<NSString *, MockAsset *> *)addV3ProfilePictureToUser:(MockUser *)user;
- (MockConnection *)insertConnectionWithSelfUser:(MockUser *)selfUser toUser:(MockUser *)toUser;

- (MockConversation *)insertSelfConversationWithSelfUser:(MockUser *)selfUser;
- (MockConversation *)insertOneOnOneConversationWithSelfUser:(MockUser *)selfUser otherUser:(MockUser *)otherUser;
- (MockConversation *)insertGroupConversationWithSelfUser:(MockUser *)selfUser otherUsers:(NSArray *)otherUsers;
- (MockConversation *)insertConversationWithSelfUser:(MockUser *)selfUser creator:(MockUser *)creator otherUsers:(nullable NSArray *)otherUsers type:(ZMTConversationType)conversationType;
- (MockConversation *)insertConversationWithCreator:(MockUser *)creator otherUsers:(NSArray *)otherUsers type:(ZMTConversationType)conversationType;

- (MockPersonalInvitation *)insertInvitationForSelfUser:(MockUser *)selfUser inviteeName:(NSString *)name mail:(NSString *)mail;
- (MockPersonalInvitation *)insertInvitationForSelfUser:(MockUser *)selfUser inviteeName:(NSString *)name phone:(NSString *)phone;
- (MockPersonalInvitation *)insertInvitationForSelfUser:(MockUser *)selfUser inviteeName:(NSString *)name mail:(nullable NSString *)mail phone:(nullable NSString *)phone;

- (MockAsset *)insertAssetWithID:(NSUUID *)assetID assetToken:(NSUUID *)assetToken assetData:(NSData *)assetData contentType:(NSString *)contentType;

- (void)setAccessTokenRenewalFailureHandler:(nullable ZMCompletionHandlerBlock)handler;
- (void)setAccessTokenRenewalSuccessHandler:(nullable ZMAccessTokenHandlerBlock)handler;

- (void)simulatePushChannelClosed;
- (void)simulatePushChannelOpened;

/// Whitelist an email so that registration is automatically verified
- (void)whiteListEmail:(NSString *)email;
/// Whitelist a phone so that we can login directly without asking for the code first (used in tests)
- (void)whiteListPhone:(NSString *)phone;

/// simulate the other party accepting a connection request
- (void)remotelyAcceptConnectionToUser:(MockUser*)user;

/// remove all stored /notification
- (void)clearNotifications;

- (MockConnection *)createConnectionRequestFromUser:(MockUser*)fromUser toUser:(MockUser*)toUser message:(nullable NSString *)message;

- (MockUserClient *)registerClientForUser:(MockUser *)user label:(NSString *)label type:(NSString *)type;

/// deletes a remote user client for a user
- (void)deleteUserClientWithIdentifier:(NSString *)identifier forUser:(MockUser *)user;

- (void)createAssetWithData:(NSData *)data identifier:(NSString *)identifier contentType:(NSString *)contentType forConversation:(NSString *)conversation;

/// Returns the user (if any) with the given remote identifier
- (nullable MockUser *)userWithRemoteIdentifier:(NSString *)remoteIdentifier;

/// Returns the client (if any) for the given remote identifier
- (nullable MockUserClient *)clientForUser:(MockUser *)user remoteIdentifier:(NSString *)remoteIdentifier;

@end



@interface MockTransportSession (IsTyping)

- (void)sendIsTypingEventForConversation:(MockConversation *)conversation user:(MockUser *)user started:(BOOL)started;

@end



@interface MockTransportSession (AVSFlowManager)

@property (nonatomic, readonly) id flowManager;
@property (nonatomic, readonly) MockFlowManager *mockFlowManager;

@end




@interface MockTransportSession (PhoneVerification)

@property (nonatomic, readonly) NSString *phoneVerificationCodeForRegistration;
@property (nonatomic, readonly) NSString *phoneVerificationCodeForLogin;
@property (nonatomic, readonly) NSString *phoneVerificationCodeForUpdatingProfile;
@property (nonatomic, readonly) NSString *invalidPhoneVerificationCode;

@end

@interface MockTransportSession (InvitationVerification)

@property (nonatomic, readonly) NSString *invitationCode;
@property (nonatomic, readonly) NSString *invalidInvitationCode;

@end

NS_ASSUME_NONNULL_END

