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


@import zimages;

#import "ZMUser.h"
#import "ZMEditableUser.h"
#import "ZMManagedObject+Internal.h"

@class ZMConnection;

extern NSString * __nonnull const SessionObjectIDKey;
extern NSString * __nonnull const ZMUserActiveConversationsKey;

@interface ZMUser (Internal)

@property (nullable, nonatomic) NSUUID *remoteIdentifier;
@property (nullable, nonatomic) ZMConnection *connection;

@property (nonnull, nonatomic) NSOrderedSet *activeConversations;

@property (nonnull, nonatomic) NSOrderedSet *showingUserAdded;
@property (nonnull, nonatomic) NSOrderedSet *showingUserRemoved;

@property (nonnull, nonatomic, readonly) NSString *normalizedName;
@property (nonnull, nonatomic, readonly) NSString *normalizedEmailAddress;

@property (nullable, nonatomic) NSData *imageMediumData;
@property (nullable, nonatomic) NSData *imageSmallProfileData;
@property (nullable, nonatomic, readonly) NSData *originalProfileImageData;

- (void)updateWithTransportData:(nonnull NSDictionary *)transportData authoritative:(BOOL)authoritative;

+ (nullable instancetype)userWithRemoteID:(nonnull NSUUID *)UUID createIfNeeded:(BOOL)create inContext:(nonnull NSManagedObjectContext *)moc;
+ (nullable instancetype)userWithEmailAddress:(nonnull NSString *)emailAddress inContext:(nonnull NSManagedObjectContext *)context;
+ (nullable instancetype)userWithPhoneNumber:(nonnull NSString *)phoneNumber inContext:(nonnull NSManagedObjectContext *)context;

+ (nonnull NSOrderedSet <ZMUser *> *)usersWithRemoteIDs:(nonnull NSOrderedSet <NSUUID *>*)UUIDs inContext:(nonnull NSManagedObjectContext *)moc;

/// @method predicateForConnectedUsersWithSearchString:
/// Retrieves users with name or email matching search string, having ZMConnectionStatusAccepted connection statuses.
/// @param searchString - a predicate to search users
+ (nonnull NSPredicate *)predicateForConnectedUsersWithSearchString:(nonnull NSString *)searchString;

/// @method predicateForUsersWithSearchString:connectionStatusInArray:
/// Retrieves users with name or email matching search string, having one of given connection statuses.
/// @param searchString - a predicate to search users
/// @param connectionStatusArray - an array of connections status of the users. E.g. for connected users it is @[@(ZMConnectionStatusAccepted)]
+ (nonnull NSPredicate *)predicateForUsersWithSearchString:(nonnull NSString *)searchString
                           connectionStatusInArray:(nonnull NSArray<NSNumber *> *)connectionStatusArray;


+ (ZMAccentColor)accentColorFromPayloadValue:(nullable NSNumber *)payloadValue;


@end

@interface ZMUser (SelfUser)

+ (nonnull instancetype)selfUserInContext:(nonnull NSManagedObjectContext *)moc;
+ (void)boxSelfUser:(ZMUser * __nonnull)selfUser inContextUserInfo:(NSManagedObjectContext * __nonnull)moc;

@end



@interface ZMUser (Editable) <ZMEditableUser>

@property (nullable, nonatomic, copy) NSString *emailAddress;
@property (nullable, nonatomic, copy) NSString *phoneNumber;

- (void)setHandle:(NSString * __nullable)handle;

@end



@interface ZMUser (ImageData) <ZMImageOwner>

@property (nullable, nonatomic) NSUUID *mediumRemoteIdentifier; ///< The remote identifier of the medium image for the receiver
@property (nullable, nonatomic) NSUUID *smallProfileRemoteIdentifier; ///< The remote identifier of the small profile image for the receiver
@property (nullable, nonatomic) NSUUID *localMediumRemoteIdentifier; ///< The remote identifier of the local "medium" image
@property (nullable, nonatomic) NSUUID *localSmallProfileRemoteIdentifier; ///< The remote identifier of the local "small profile" image
@property (nullable, nonatomic) NSUUID *imageCorrelationIdentifier; ///< Correlation id for the profile image

+ (nonnull NSPredicate *)predicateForMediumImageNeedingToBeUpdatedFromBackend;
+ (nonnull NSPredicate *)predicateForSmallImageNeedingToBeUpdatedFromBackend;
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

