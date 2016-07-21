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
@import ZMUtilities;
@import ZMCSystem;
@import ZMTransport;
@import CoreData;

@class MockPicture;
@class MockUserClient;
@class MockPreKey;
@class MockConversation;

extern NSString *const ZMSearchUserMutualFriendsKey;
extern NSString *const ZMSearchUserTotalMutualFriendsKey;


@interface MockUser : NSManagedObject

@property (nonatomic) NSString *email;
@property (nonatomic) NSString *password;
@property (nonatomic) NSString *phone;
@property (nonatomic) int16_t accentID;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString *trackingIdentifier;
@property (nonatomic) NSOrderedSet *pictures;
@property (nonatomic) BOOL isEmailValidated;
@property (nonatomic) BOOL isSendingVideo;
@property (nonatomic) MockConversation *ignoredCallConversation;

@property (nonatomic) NSOrderedSet *connectionsFrom;
@property (nonatomic) NSOrderedSet *connectionsTo;
@property (nonatomic) NSOrderedSet *activeCallConversations;

@property (nonatomic) NSMutableSet *clients;

@property (nonatomic) NSOrderedSet *invitations;

- (id<ZMTransportData>)transportData;
- (id<ZMTransportData>)transportDataWhenNotConnected;

+ (NSFetchRequest *)sortedFetchRequest;
+ (NSFetchRequest *)sortedFetchRequestWithPredicate:(NSPredicate *)predicate;
- (NSString *)mediumImageIdentifier;
- (NSString *)smallProfileImageIdentifier;
- (MockPicture *)smallProfileImage;
- (MockPicture *)mediumImage;


@end
