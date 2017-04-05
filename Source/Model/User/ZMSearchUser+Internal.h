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


#import "ZMSearchUser.h"
#import <WireUtilities/ZMAccentColor.h>
#import "ZMManagedObjectContextProvider.h"

@class ZMUser;
@class ZMAddressBookContact;
@class ManagedObjectContextObserver;
@class SearchUserObserverCenter;

FOUNDATION_EXPORT NSString *const ZMSearchUserTotalMutualFriendsKey;

@interface ZMSearchUser ()

- (instancetype)initWithName:(NSString *)name
                      handle:(NSString *)handle
                 accentColor:(ZMAccentColor)color
                    remoteID:(NSUUID *)remoteID
                        user:(ZMUser *)user
    syncManagedObjectContext:(NSManagedObjectContext *)syncMOC
      uiManagedObjectContext:(NSManagedObjectContext *)uiMOC;

- (instancetype)initWithName:(NSString *)name
                      handle:(NSString *)handle
                 accentColor:(ZMAccentColor)color
                    remoteID:(NSUUID *)remoteID
                        user:(ZMUser *)user
                 userSession:(id<ZMManagedObjectContextProvider>)userSession;

+ (NSArray <ZMSearchUser *> *)usersWithUsers:(NSArray <ZMUser *> *)users userSession:(id<ZMManagedObjectContextProvider>)userSession;

- (instancetype)initWithPayload:(NSDictionary *)payload userSession:(id<ZMManagedObjectContextProvider>)userSession;

+ (NSArray <ZMSearchUser *> *)usersWithPayloadArray:(NSArray <NSDictionary *> *)payloadArray userSession:(id<ZMManagedObjectContextProvider> )userSession;

- (instancetype)initWithContact:(ZMAddressBookContact *)contact user:(ZMUser *)user userSession:(id<ZMManagedObjectContextProvider> )userSession;

@property (nonatomic) NSUUID *remoteIdentifier;
/// Returns @c YES if the receiver has a local user or cached profile image data.
/// C.f. +searchUserToProfileImageCache
@property (nonatomic, readonly) BOOL isLocalOrHasCachedProfileImageData;

@property (nonatomic) NSUUID *mediumLegacyId;
@property (nonatomic) NSString *completeAssetKey;

@property (nonatomic, readwrite) NSUInteger totalCommonConnections;

+ (NSCache *)searchUserToSmallProfileImageCache;
+ (NSCache *)searchUserToMediumImageCache;
+ (NSCache *)searchUserToMediumAssetIDCache;

- (void)setAndNotifyNewMediumImageData:(NSData *)data searchUserObserverCenter:(SearchUserObserverCenter *)searchUserObserverCenter;
- (void)notifyNewSmallImageData:(NSData *)data searchUserObserverCenter:(SearchUserObserverCenter *)searchUserObserverCenter;

@end
