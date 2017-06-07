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


#import <WireUtilities/ZMAccentColor.h>

@class Team;

/// The minimal set of properties and methods that something User-like must include
@protocol ZMBareUser <NSObject>

/// The full name
@property (nonatomic, readonly) NSString *name;
/// The given name / first name e.g. "John" for "John Smith"
@property (nonatomic, readonly) NSString *displayName;
/// The initials e.g. "JS" for "John Smith"
@property (nonatomic, readonly) NSString *initials;
/// The "@name" handle
@property (nonatomic, readonly) NSString *handle;

/// whether this is the self user
@property (nonatomic, readonly) BOOL isSelfUser;

@property (nonatomic, readonly) NSString *smallProfileImageCacheKey;
@property (nonatomic, readonly) NSString *mediumProfileImageCacheKey;


@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, readonly) ZMAccentColor accentColorValue;

@property (nonatomic, readonly) NSData *imageMediumData;
@property (nonatomic, readonly) NSData *imageSmallProfileData;
/// This is a unique string that will change only when the @c imageSmallProfileData changes
@property (nonatomic, readonly) NSString *imageSmallProfileIdentifier;
@property (nonatomic, readonly) NSString *imageMediumIdentifier;


/// Is @c YES if we can send a connection request to this user.
@property (nonatomic, readonly) BOOL canBeConnected;

/// Request a refresh of the user data from the backend.
/// This is useful for non-connected user, that we will otherwise never refetch
- (void)refreshData;

/// Sends a connection request to the given user. May be a no-op, eg. if we're already connected.
/// A ZMUserChangeNotification with the searchUser as object will be sent notifiying about the connection status change
/// You should stop from observing the searchUser and start observing the user from there on
- (void)connectWithMessageText:(NSString *)text completionHandler:(dispatch_block_t)handler;

/// Returns YES if the user is a member of the team
- (BOOL)isMemberOf:(Team *)team;

/// Returns an array of teams where the user is a guest in any team conversation
@property (nonatomic, readonly) NSArray<Team *>* guestInTeams;

@property (nonatomic, readonly, copy) NSString *connectionRequestMessage;
@property (nonatomic, readonly) NSUInteger totalCommonConnections;

@end



@protocol ZMBareUserConnection <NSObject>

@property (nonatomic, readonly) BOOL isPendingApprovalByOtherUser;

@end
