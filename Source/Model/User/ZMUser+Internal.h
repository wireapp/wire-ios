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


@import WireImages;

#import "ZMUser.h"
#import "ZMEditableUser.h"
#import "ZMManagedObject+Internal.h"
#import "ZMUser+OneOnOne.h"

@class ZMConnection;
@class Team;

extern NSString * __nonnull const SessionObjectIDKey;
extern NSString * __nonnull const UserClientsKey;
extern NSString * __nonnull const AvailabilityKey;
extern NSString * __nonnull const ReadReceiptsEnabledKey;

@interface ZMUser (Internal)

@property (null_unspecified, nonatomic) NSUUID *remoteIdentifier;
@property (nullable, nonatomic) ZMConnection *connection;

@property (nullable, nonatomic) NSUUID *teamIdentifier;

@property (nonnull, nonatomic) NSSet *showingUserAdded;
@property (nonnull, nonatomic) NSSet *showingUserRemoved;

@property (nonnull, nonatomic) NSSet<Team *> *createdTeams;

@property (nonnull, nonatomic, readonly) NSString *normalizedName;
@property (nonnull, nonatomic, readonly) NSString *normalizedEmailAddress;

@property (nullable, nonatomic) NSData *imageMediumData;
@property (nullable, nonatomic) NSData *imageSmallProfileData;

- (void)updateWithTransportData:(nonnull NSDictionary *)transportData authoritative:(BOOL)authoritative;

+ (nullable instancetype)userWithRemoteID:(nonnull NSUUID *)UUID createIfNeeded:(BOOL)create inContext:(nonnull NSManagedObjectContext *)moc;
+ (nullable instancetype)userWithEmailAddress:(nonnull NSString *)emailAddress inContext:(nonnull NSManagedObjectContext *)context;
+ (nullable instancetype)userWithPhoneNumber:(nonnull NSString *)phoneNumber inContext:(nonnull NSManagedObjectContext *)context;

+ (nonnull NSOrderedSet <ZMUser *> *)usersWithRemoteIDs:(nonnull NSOrderedSet <NSUUID *>*)UUIDs inContext:(nonnull NSManagedObjectContext *)moc;

+ (ZMAccentColor)accentColorFromPayloadValue:(nullable NSNumber *)payloadValue;

/// @method Updates the user with a name or handle received through a search
/// Should be called when creating a @c ZMSearchUser to ensure it's underlying user is updated.
- (void)updateWithSearchResultName:(nullable NSString *)name handle:(nullable NSString *)handle;


@end

@interface ZMUser (SelfUser)

+ (nonnull instancetype)selfUserInContext:(nonnull NSManagedObjectContext *)moc;
+ (void)boxSelfUser:(ZMUser * __nonnull)selfUser inContextUserInfo:(NSManagedObjectContext * __nonnull)moc;

@end



@interface ZMUser (Editable) <ZMEditableUser>

@property (nullable, nonatomic, copy) NSString *emailAddress;
@property (nullable, nonatomic, copy) NSString *phoneNumber;
@property (nullable, nonatomic, copy) NSString *name;
@property (nonatomic) ZMAccentColor accentColorValue;

- (void)setHandle:(NSString * __nullable)handle;
@property (nonatomic) BOOL needsPropertiesUpdate;
@property (nonatomic) BOOL readReceiptsEnabledChangedRemotely;
@end



@interface ZMUser (ImageData)

@property (nullable, nonatomic) NSUUID *mediumRemoteIdentifier; ///< The remote identifier of the medium image for the receiver
@property (nullable, nonatomic) NSUUID *smallProfileRemoteIdentifier; ///< The remote identifier of the small profile image for the receiver
@property (nullable, nonatomic) NSUUID *localMediumRemoteIdentifier; ///< The remote identifier of the local "medium" image
@property (nullable, nonatomic) NSUUID *localSmallProfileRemoteIdentifier; ///< The remote identifier of the local "small profile" image

+ (nonnull NSPredicate *)predicateForMediumImageNeedingToBeUpdatedFromBackend;
+ (nonnull NSPredicate *)predicateForSmallImageNeedingToBeUpdatedFromBackend;
+ (nonnull NSPredicate *)predicateForSelfUser;
+ (nonnull NSPredicate *)predicateForUsersOtherThanSelf;
+ (nonnull NSPredicate *)predicateForMediumImageDownloadFilter;
+ (nonnull NSPredicate *)predicateForSmallImageDownloadFilter;

@end



@interface NSUUID (SelfUser)

- (BOOL)isSelfUserRemoteIdentifierInContext:(nonnull NSManagedObjectContext *)moc;

@end




@interface ZMSession : ZMManagedObject

@property (nonnull, nonatomic, strong) ZMUser *selfUser;

@end




@interface ZMUser (OTR)

- (nullable UserClient *)selfClient;

@end




@class ZMUserId;

@interface ZMUser (Protobuf)

- (nonnull ZMUserId *)userId;

@end

