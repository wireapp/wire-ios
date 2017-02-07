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


#import "ZMDisplayNameGenerator.h"

@class ZMUser;

@interface ZMUserDisplayNameGenerator : ZMDisplayNameGenerator

// Takes a dictionary of keys to users and returns a dictionary of keys to displayName and keys to initials by calling its super class
// Creates a copy using its superclass and a strong reference to allUsers
- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc NS_DESIGNATED_INITIALIZER;

- (NSString *)displayNameForUser:(ZMUser *)user;
- (NSString *)initialsForUser:(ZMUser *)user;

@end



@interface NSManagedObjectContext (ZMDisplayNameGenerator)

// ManagedObjectContext holds reference to displayNameGenerator in userInfo
// User updates and insertions call updateDisplayNameGeneratorWithInsertedUsers:updatedUsers:deletedUsers
// this creates a copy of the old displayNameGenerator and replaces the old one and returns a set of userIDS whose names changed
// For each item in that set UserChangeNotifications are created

@property (nonatomic) ZMUserDisplayNameGenerator *displayNameGenerator;

/// Returns those ZMUser instances for which names have been updated, and updates the internal name generator
- (NSSet<ZMUser *> *)updateDisplayNameGeneratorWithUpdatedUsers:(NSSet<ZMUser *>*)updatedUsers
                                        insertedUsers:(NSSet<ZMUser *>*)insertedUsers
                                         deletedUsers:(NSSet<ZMUser *>*)deletedUsers;
@end
