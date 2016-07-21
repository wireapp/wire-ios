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


@import Foundation;
@import CoreData;


@interface ZMDisplayNameGenerator : NSObject

// Takes a dictionary of keys to fullNames and returns a dictionary keys to displayNames & a map key initials (with key to
// personName and fullName to personName intermediates)
// Creates a copy by comparing the new full names with items in the fullName to PersonName map, only creating new personName
// instances for new fullNames, changes pointer

- (instancetype)createCopyWithMap:(NSDictionary *)map updatedKeys:(NSSet **)updated;

- (NSString *)displayNameForKey:(id <NSCopying>)key;
- (NSString *)initialsForKey:(id <NSCopying>)key;

@end
