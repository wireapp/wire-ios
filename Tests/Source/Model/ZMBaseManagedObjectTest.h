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


@import ZMTesting;
@import ZMCDataModel;

#import "NSManagedObjectContext+TestHelpers.h"
#import "ZMUser.h"


@class ZMEventID;
@class NSManagedObjectContext;
@class ZMManagedObject;
@class ZMUser;
@class ZMConversation;
@class ZMConnection;
@protocol ZMObjectStrategyDirectory;
@class ZMAssetClientMessage;
@class ZMTestSession;

@import Cryptobox;
@import zimages;
@class UserClient;

@class ZMClientMessage;

/// This is a base test class with utility stuff for all tests.
@interface ZMBaseManagedObjectTest : ZMTBaseTest

/// Waits for queues and managed object contexts to finish work and verifies mocks
- (void)cleanUpAndVerify;

- (ZMEventID *)createEventID;
+ (ZMEventID *)createEventID;

@property (nonatomic, readonly) ZMTestSession *testSession;
@property (nonatomic, readonly) NSManagedObjectContext *uiMOC;
@property (nonatomic, readonly) NSManagedObjectContext *syncMOC;
@property (nonatomic, readonly) NSManagedObjectContext *searchMOC;


/// reset ui and sync contexts
- (void)resetUIandSyncContextsAndResetPersistentStore:(BOOL)resetPersistantStore;

/// perform operations pretending that the uiMOC is a syncMOC
- (void)performPretendingUiMocIsSyncMoc:(void(^)(void))block;

@end



@interface ZMBaseManagedObjectTest (DisplayNameGenerator)

- (void)updateDisplayNameGeneratorWithUsers:(NSArray *)users;

@end



@interface ZMBaseManagedObjectTest (UserTesting)

- (void)setEmailAddress:(NSString *)emailAddress onUser:(ZMUser *)user;
- (void)setPhoneNumber:(NSString *)phoneNumber onUser:(ZMUser *)user;

@end



@interface ZMBaseManagedObjectTest (FilesInCache)

/// Sets up the asset caches on the managed object contexts
- (void)setUpCaches;

/// Wipes the asset caches on the managed object contexts
- (void)wipeCaches;

@end


@interface ZMBaseManagedObjectTest (OTR)

- (UserClient *)createSelfClient;
- (UserClient *)createClientForUser:(ZMUser *)user createSessionWithSelfUser:(BOOL)createSessionWithSeflUser;


- (ZMClientMessage *)createClientTextMessage:(BOOL)encrypted;
- (ZMClientMessage *)createClientTextMessage:(NSString *)text encrypted:(BOOL)encrypted;
- (ZMAssetClientMessage *)createImageMessageWithImageData:(NSData *)imageData
                                                   format:(ZMImageFormat)format
                                                processed:(BOOL)processed
                                                   stored:(BOOL)stored
                                                encrypted:(BOOL)encrypted
                                                      moc:(NSManagedObjectContext *)moc;

@end


@interface ZMBaseManagedObjectTest (SwiftBridgeConversation)

- (void)simulateUnreadCount:(NSUInteger)unreadCount forConversation:(ZMConversation *)conversation;
- (void)simulateUnreadMissedCallInConversation:(ZMConversation *)conversation;
- (void)simulateUnreadMissedKnockInConversation:(ZMConversation *)conversation;

@end

