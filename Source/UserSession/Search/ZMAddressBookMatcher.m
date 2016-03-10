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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


#import "ZMAddressBookMatcher.h"
#import "ZMAddressBookContact.h"
#import "ZMUser.h"
#import "ZMUserSession+Internal.h"
#import "ZMSearchUser+Internal.h"

@interface ZMAddressBookMatcher ()

@property (nonatomic, readonly) NSArray *contacts;

@end


@implementation ZMAddressBookMatcher

- (instancetype)initWithUserSession:(ZMUserSession *)userSession
{
    return [self initWithContacts:userSession.addressBookContacts];
}

- (instancetype)initWithContacts:(NSArray *)contacts
{
    self = [super init];
    
    if (self) {
        _contacts = contacts;
    }
    
    return self;
}

- (NSArray *)contactsMatchingQuery:(NSString *)query
{
    if (query.length == 0) {
        return self.contacts;
    } else {
        return [self.contacts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.name CONTAINS[cd] %@", query]];
    }
}

- (ZMAddressBookContact *)contactForUser:(ZMUser *)user
{
    ZMAddressBookContact *matchedContact;
    
    for (ZMAddressBookContact *contact in self.contacts) {
        
        if (user.emailAddress.length > 0 && [contact.emailAddresses containsObject:user.emailAddress]) {
            matchedContact = contact;
            break;
        }
        
        if (user.phoneNumber.length > 0 && [contact.phoneNumbers containsObject:user.phoneNumber]) {
            matchedContact = contact;
            break;
        }
    }
    
    return matchedContact;
}

- (NSIndexSet *)matchUsers:(NSArray *)users withContacts:(NSArray *)contacts block:(void (^)(ZMAddressBookContact *contact, ZMUser *user))block
{
    NSMutableDictionary *phoneNumberIndex = [NSMutableDictionary dictionary];
    NSMutableDictionary *emailAddressIndex = [NSMutableDictionary dictionary];
    
    for (ZMUser *user in users) {
        
        if (user.phoneNumber.length > 0) {
            [phoneNumberIndex setObject:user forKey:user.phoneNumber];
        }
        
        if (user.emailAddress.length > 0) {
            [emailAddressIndex setObject:user forKey:user.emailAddress];
        }
    }
    
    NSMutableIndexSet *matchedIndexSet = [NSMutableIndexSet indexSet];
    
    for (ZMAddressBookContact *contact in contacts) {
        ZMUser *matchedUser = nil;
        
        for (NSString *emailAddress in contact.emailAddresses) {
            matchedUser = [emailAddressIndex objectForKey:emailAddress];
            
            if (matchedUser != nil) {
                [matchedIndexSet addIndex:[users indexOfObject:matchedUser]];
                break;
            }
        }
        
        if (matchedUser == nil) {
            for (NSString *phoneNumber in contact.phoneNumbers) {
                matchedUser = [phoneNumberIndex objectForKey:phoneNumber];
                
                if (matchedUser != nil) {
                    [matchedIndexSet addIndex:[users indexOfObject:matchedUser]];
                    break;
                }
            }
        }
        
        block(contact, matchedUser);
    }
    
    NSMutableArray *unmatchedUsers = [users mutableCopy];
    [unmatchedUsers removeObjectsAtIndexes:matchedIndexSet];
    
    for (ZMUser *user in unmatchedUsers) {
        block(nil, user);
    }
    
    return matchedIndexSet;
}

@end
