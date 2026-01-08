//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

@import WireUtilities;

#import <Foundation/Foundation.h>
#import "MessagingTest.h"

@interface NSString_NormalizationTests : MessagingTest

@end

@implementation NSString_NormalizationTests


- (void)testThatItConvertsToLowercase
{
    NSString *normalizedString = [@"SomEThIng" normalizedString];
    
    XCTAssertEqualObjects(normalizedString, @"something");
}


- (void)testThatItRemovesDiacritics
{
    NSString *normalizedString = [@"sömëthîñg" normalizedString];
    XCTAssertEqualObjects(normalizedString, @"something");
    
    NSString *normalizedString2 = [@"Håkon Bø" normalizedString];
    XCTAssertEqualObjects(normalizedString2, @"hakon bo");

}


- (void)testThatItConvertsToLatin
{
    NSString *normalizedString = [@"שלום" normalizedString];
    XCTAssertEqualObjects(normalizedString, @"slwm");

    NSString *normalizedString2 = [@"안녕하세요" normalizedString];
    XCTAssertEqualObjects(normalizedString2, @"annyeonghaseyo");

    NSString *normalizedString3 = [@"ひらがな" normalizedString];
    XCTAssertEqualObjects(normalizedString3, @"hiragana");
}

- (void)testThatItRemovesNonAlphaNumericCharacters
{
    NSString *normalizedString = [@"😍hey😍hey😍hey😍hey😍hey😍hey😍hey😍" normalizedString];
    XCTAssertEqualObjects(normalizedString, @"heyheyheyheyheyheyhey");
    
    NSString *normalizedString2 = [@"#hey" normalizedString];
    XCTAssertEqualObjects(normalizedString2, @"hey");
    
    NSString *normalizedString3 = [@"@hey" normalizedString];
    XCTAssertEqualObjects(normalizedString3, @"hey");
    
    NSString *normalizedString4 = [@"(hey)" normalizedString];
    XCTAssertEqualObjects(normalizedString4, @"hey");
    
    NSString *normalizedString5 = [@"😍😍" normalizedString];
    XCTAssertEqualObjects(normalizedString5, @"");
    
    NSString *normalizedString6 = [@"😍😍hey" normalizedString];
    XCTAssertEqualObjects(normalizedString6, @"hey");

}

- (void)testThatItDoesNotRemoveWhiteSpaceCharacters
{
    NSString *normalizedString = [@"hey you" normalizedString];
    XCTAssertEqualObjects(normalizedString, @"hey you");
    
}


- (void)testThatItDoesNotRemoveSpecialCharactersInEmailaddresses
{
    NSString *normalizedEmailaddress = [@"hallo-du@example.com" normalizedEmailaddress];
    XCTAssertEqualObjects(normalizedEmailaddress, @"hallo-du@example.com");
}



@end
