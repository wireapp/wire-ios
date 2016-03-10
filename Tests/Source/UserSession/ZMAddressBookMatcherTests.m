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


#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "MessagingTest.h"
#import "ZMAddressBookMatcher.h"
#import "ZMAddressBookContact.h"
#import "ZMUser+Internal.h"

@interface ZMAddressBookMatcherTests : MessagingTest

@end

@implementation ZMAddressBookMatcherTests

- (void)testThatContactForUserMatchesOnPhoneNumber {
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.phoneNumber = @"+591023901222";
    
    ZMAddressBookContact *contact = [[ZMAddressBookContact alloc] init];
    contact.phoneNumbers = @[@"+46ß02239202", user.phoneNumber];
    
    ZMAddressBookMatcher *matcher = [[ZMAddressBookMatcher alloc] initWithContacts:@[contact]];
    
    // when
    ZMAddressBookContact *matchedContact = [matcher contactForUser:user];
    
    // Then
    XCTAssertEqualObjects(contact, matchedContact);
}

- (void)testThatContactForUserMatchesOnEmailAddress {
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.emailAddress = @"john.doe@example.com";
    
    ZMAddressBookContact *contact = [[ZMAddressBookContact alloc] init];
    contact.emailAddresses = @[@"work@example.com", user.emailAddress];
    
    ZMAddressBookMatcher *matcher = [[ZMAddressBookMatcher alloc] initWithContacts:@[contact]];
    
    // when
    ZMAddressBookContact *matchedContact = [matcher contactForUser:user];
    
    // Then
    XCTAssertEqualObjects(contact, matchedContact);
}

- (void)testThatMatchUsersWithContactsReturnsCorrectIndexSet
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user1.emailAddress = @"john.doe@example.com";
    
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user2.phoneNumber = @"+030492342333";
    
    ZMUser *user3 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user3.phoneNumber = @"+591023901222";
    
    NSArray *users = @[user1, user2, user3];
    
    ZMAddressBookContact *contact1 = [[ZMAddressBookContact alloc] init];
    contact1.emailAddresses = @[@"work@example.com", user1.emailAddress];
    
    ZMAddressBookContact *contact2 = [[ZMAddressBookContact alloc] init];
    contact2.emailAddresses = @[@"eva@example.com"];
    
    ZMAddressBookContact *contact3 = [[ZMAddressBookContact alloc] init];
    contact3.phoneNumbers = @[user3.phoneNumber];
    
    NSArray *contacts = @[contact1, contact2, contact3];
    
    ZMAddressBookMatcher *matcher = [[ZMAddressBookMatcher alloc] initWithContacts:contacts];
    
    // when
    NSIndexSet *matchedIndexSet = [matcher matchUsers:users withContacts:contacts block:^(ZM_UNUSED ZMAddressBookContact *contact, ZMUser *matchedUser) {
        if (matchedUser != nil) {
            XCTAssertTrue([users containsObject:matchedUser]);
        }
    }];
    
    // then
    NSMutableIndexSet *expectedIndexSet = [[NSMutableIndexSet alloc] init];
    [expectedIndexSet addIndex:0];
    [expectedIndexSet addIndex:2];
    
    XCTAssertEqualObjects(matchedIndexSet, [expectedIndexSet copy]);
}

- (void)testThatContactsMatchingQueryFiltersByNameIgnoringCaseAndDiacritic
{
    // given
    ZMAddressBookContact *contact1 = [[ZMAddressBookContact alloc] init];
    contact1.firstName = @"Judy";
    
    ZMAddressBookContact *contact2 = [[ZMAddressBookContact alloc] init];
    contact2.firstName = @"Anna";
    
    ZMAddressBookContact *contact3 = [[ZMAddressBookContact alloc] init];
    contact3.firstName = @"Lisa";
    
    ZMAddressBookContact *contact4 = [[ZMAddressBookContact alloc] init];
    contact4.firstName = @"Åsa";
    
    
    NSArray *contacts = @[contact1, contact2, contact3, contact4];
    
    ZMAddressBookMatcher *matcher = [[ZMAddressBookMatcher alloc] initWithContacts:contacts];
    
    // when
    NSArray *matchingContacts = [matcher contactsMatchingQuery:@"a"];
    
    
    // then
    NSArray *expectedMatchingContacts = @[contact2, contact3, contact4];
    XCTAssertEqualObjects(matchingContacts, expectedMatchingContacts);
}

@end
