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


#import <Foundation/Foundation.h>

@class ZMUser, ZMUserSession, ZMAddressBookContact;

@interface ZMAddressBookMatcher : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Returns a address book matcher with contacts from a user session.
- (instancetype)initWithUserSession:(ZMUserSession *)userSession;

/// Returns a address book matcher which perform matching operations on the array of contacts.
- (instancetype)initWithContacts:(NSArray *)contacts NS_DESIGNATED_INITIALIZER;

/// Returns a contact matching a user based on email address or phone number.
- (ZMAddressBookContact *)contactForUser:(ZMUser *)user;

/// Returns an index set over the users matched to contacts. For each contact
/// the block is called with the contact and/or matching user if a match was
/// found otherwise nil.
- (NSIndexSet *)matchUsers:(NSArray *)users withContacts:(NSArray *)contacts block:(void (^)(ZMAddressBookContact *contact, ZMUser *matchedUser))block;

/// Returns contacts filtered by the query.
- (NSArray *)contactsMatchingQuery:(NSString *)query;

@end
