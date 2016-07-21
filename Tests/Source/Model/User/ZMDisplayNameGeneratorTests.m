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


#import "ZMBaseManagedObjectTest.h"
#import "ZMDisplayNameGenerator+Internal.h"
#import "ZMPersonName.h"

@interface ZMDisplayNameGeneratorTests : ZMBaseManagedObjectTest
@end

@implementation ZMDisplayNameGeneratorTests

- (void)setUp
{
    [super setUp];
}

- (void)testThatItReturnsFirstNameForUserWithDifferentFirstnames;
{
    // given
    
    NSString *fullName1 = @"Rob A";
    NSString *fullName2 = @"Henry B";
    NSString *fullName3 = @"Arthur";
    NSString *fullName4 = @"Kevin ()";
    
    // when
    
    NSDictionary *map = @{@"A": fullName1,
                          @"B": fullName2,
                          @"C": fullName3,
                          @"D": fullName4};
    
    ZMDisplayNameGenerator *nameGenerator = [[ZMDisplayNameGenerator alloc] init];
    nameGenerator.idToFullNameMap = map;
    
    NSString *displayNameForKey1 = [nameGenerator displayNameForKey:@"A"];
    NSString *displayNameForKey2 = [nameGenerator displayNameForKey:@"B"];
    NSString *displayNameForKey3 = [nameGenerator displayNameForKey:@"C"];
    NSString *displayNameForKey4 = [nameGenerator displayNameForKey:@"D"];

    // then
    
    XCTAssertEqualObjects(displayNameForKey1, @"Rob");
    XCTAssertEqualObjects(displayNameForKey2, @"Henry");
    XCTAssertEqualObjects(displayNameForKey3, @"Arthur");
    XCTAssertEqualObjects(displayNameForKey4, @"Kevin");
}

- (void)testThatItReturnsAbbreviatedNameForUserWithSameFirstnamesDifferentLastnameFirstLetter;
{
    // given
    
    NSString *fullName1 = @"Rob Arthur";
    NSString *fullName2 = @"Rob Benjamin";
    NSString *fullName3 = @"Rob (Christopher)";
    NSString *fullName4 = @"Rob Benjamin Henry";
    NSString *fullName5 = @"Rob Christopher Benjamin";
    
    // when
    
    NSDictionary *map = @{@"A": fullName1,
                          @"B": fullName2,
                          @"C": fullName3,
                          @"D": fullName4,
                          @"E": fullName5};
    
    ZMDisplayNameGenerator *nameGenerator = [[ZMDisplayNameGenerator alloc] init];
    nameGenerator.idToFullNameMap = map;

    // then

    XCTAssertEqualObjects([nameGenerator displayNameForKey:@"A"], @"Rob A");
    XCTAssertEqualObjects([nameGenerator displayNameForKey:@"B"], fullName2);
    XCTAssertEqualObjects([nameGenerator displayNameForKey:@"C"], @"Rob C");
    XCTAssertEqualObjects([nameGenerator displayNameForKey:@"D"], @"Rob H");
    XCTAssertEqualObjects([nameGenerator displayNameForKey:@"E"], fullName5);
    
}

- (void)testThatItReturnsFullNameForUserWithSameFirstnamesAndSameLastnameFirstLetter;
{
    // given
    NSString *fullName1 = @"Rob Arthur";
    NSString *fullName2 = @"Rob Anthony";
    NSString *fullName3 = @"Rob Benjamin";
    
    // when
    
    NSDictionary *map = @{@"A": fullName1,
                          @"B": fullName2,
                          @"C": fullName3};
    
    ZMDisplayNameGenerator *nameGenerator = [[ZMDisplayNameGenerator alloc] init];
    nameGenerator.idToFullNameMap = map;
    
    NSString *displayNameForKey1 = [nameGenerator displayNameForKey:@"A"];
    NSString *displayNameForKey2 = [nameGenerator displayNameForKey:@"B"];
    NSString *displayNameForKey3 = [nameGenerator displayNameForKey:@"C"];
    
    // then

    XCTAssertEqualObjects(displayNameForKey1, @"Rob Arthur");
    XCTAssertEqualObjects(displayNameForKey2, @"Rob Anthony");
    XCTAssertEqualObjects(displayNameForKey3, @"Rob B");
}

- (void)testThatItReturnsFullNameForUsersWithDifferentlyComposedSpecialCharacters
{

    // given
    NSString *name1 = @"Henry \u00cblse"; // LATIN CAPITAL LETTER E WITH DIAERESIS
    NSString *name2 = @"Henry E\u0308mil"; // LATIN CAPITAL LETTER E + COMBINING DIAERESIS
    
    // when
    
    NSDictionary *map = @{@"A": name1,
                          @"B": name2};
    
    ZMDisplayNameGenerator *nameGenerator = [[ZMDisplayNameGenerator alloc] init];
    nameGenerator.idToFullNameMap = map;
    
    NSString *displayNameForKey1 = [nameGenerator displayNameForKey:@"A"];
    NSString *displayNameForKey2 = [nameGenerator displayNameForKey:@"B"];
    
    // then
    XCTAssertEqualObjects(displayNameForKey1, @"Henry \u00cblse");
    XCTAssertEqualObjects(displayNameForKey2, @"Henry \u00cbmil");
}


- (void)testThatItReturnsAbbreviatedNameForSameFirstnamesWithDifferentlyComposedCharacters
{
    // given
    NSString *name1 = @"\u00C5ron Meister";
    NSString *name2 = @"A\u030Aron Hans";
    
    // when
    NSDictionary *map = @{@"A": name1,
                          @"B": name2};
    
    ZMDisplayNameGenerator *nameGenerator = [[ZMDisplayNameGenerator alloc] init];
    nameGenerator.idToFullNameMap = map;
    
    NSString *displayNameForKey1 = [nameGenerator displayNameForKey:@"A"];
    NSString *displayNameForKey2 = [nameGenerator displayNameForKey:@"B"];
    
    // then
    XCTAssertEqualObjects(displayNameForKey1, @"\u00C5ron M");
    XCTAssertEqualObjects(displayNameForKey2, @"\u00C5ron H");
}


- (void)testThatItReturnsUpdatedDisplayNamesWhenInitializedWithCopy
{
    // given
    NSString *name1 = @"\u00C5ron Meister";
    NSString *name2a = @"A\u030Aron Hans";
    NSString *name2b = @"A\u030Arif Hans";
    
    // when
    NSDictionary *map1 = @{@"A": name1,
                          @"B": name2a};
    
    ZMDisplayNameGenerator *nameGenerator = [[ZMDisplayNameGenerator alloc] init];
    nameGenerator.idToFullNameMap = map1;
    
    NSString *displayNameForKey1 = [nameGenerator displayNameForKey:@"A"];
    NSString *displayNameForKey2 = [nameGenerator displayNameForKey:@"B"];
    
    // then
    XCTAssertEqualObjects(displayNameForKey1, @"\u00C5ron M");
    XCTAssertEqualObjects(displayNameForKey2, @"\u00C5ron H");
    
    // when
    NSDictionary *map2 = @{@"A": name1,
                          @"B": name2b,};
    
    NSSet *updated = [NSSet set];
    ZMDisplayNameGenerator *newGenerator = [nameGenerator createCopyWithMap:map2 updatedKeys:&updated];
    
    NSString *displayNameForKey3 = [newGenerator displayNameForKey:@"A"];
    NSString *displayNameForKey4 = [newGenerator displayNameForKey:@"B"];
    
    NSString *displayNameForKey5 = [nameGenerator displayNameForKey:@"A"];
    NSString *displayNameForKey6 = [nameGenerator displayNameForKey:@"B"];
    
    NSSet *updatedSet = [NSSet setWithArray:@[@"A", @"B"]];
    
    // then
    XCTAssertEqualObjects(displayNameForKey3, @"\u00C5ron");
    XCTAssertEqualObjects(displayNameForKey4, @"\u00C5rif");
    
    XCTAssertEqualObjects(displayNameForKey5, @"\u00C5ron M");
    XCTAssertEqualObjects(displayNameForKey6, @"\u00C5ron H");
    
    XCTAssertEqualObjects(updated, updatedSet);
}

- (void)testThatItReturnsUpdatedDisplayNamesWhenInitializedWithCopyAddingOneName
{
    // given
    NSString *name1 = @"\u00C5ron Meister";
    NSString *name2 = @"A\u030Aron Hans";
    NSString *name3 = @"A\u030Aron Hans";
    
    // when
    NSDictionary *map = @{@"A": name1,
                          @"B": name2};
    
    ZMDisplayNameGenerator *nameGenerator = [[ZMDisplayNameGenerator alloc] init];
    nameGenerator.idToFullNameMap = map;
    
    NSString *displayNameForKey1 = [nameGenerator displayNameForKey:@"A"];
    NSString *displayNameForKey2 = [nameGenerator displayNameForKey:@"B"];
    
    // then
    XCTAssertEqualObjects(displayNameForKey1, @"\u00C5ron M");
    XCTAssertEqualObjects(displayNameForKey2, @"\u00C5ron H");
    
    // when
    
    // We create a second Generator using the old one 
    NSDictionary *map1 = @{@"A": name1,
                          @"B": name2,
                          @"C": name3 };
    
    NSSet *updated = [NSSet set];
    ZMDisplayNameGenerator *newGenerator = [nameGenerator createCopyWithMap:map1 updatedKeys:&updated];
    
    NSString *displayNameForKey3 = [newGenerator displayNameForKey:@"A"];
    NSString *displayNameForKey4 = [newGenerator displayNameForKey:@"B"];
    NSString *displayNameForKey5 = [newGenerator displayNameForKey:@"C"];

    NSString *displayNameForKey6 = [nameGenerator displayNameForKey:@"A"];
    NSString *displayNameForKey7 = [nameGenerator displayNameForKey:@"B"];
    NSSet *updatedSet = [NSSet setWithArray:@[@"B", @"C"]];
    
    
    // then
    XCTAssertEqualObjects(displayNameForKey3, @"\u00C5ron M");
    XCTAssertEqualObjects(displayNameForKey4, [name2 precomposedStringWithCanonicalMapping]);
    XCTAssertEqualObjects(displayNameForKey5, [name3 precomposedStringWithCanonicalMapping]);
    
    XCTAssertEqualObjects(displayNameForKey6, @"\u00C5ron M");
    XCTAssertEqualObjects(displayNameForKey7, @"\u00C5ron H");
    
    XCTAssertEqualObjects(updated, updatedSet);
    
}


- (void)testThatItReturnsUpdatedDisplayNamesWhenTheInitialMapWasEmpty
{
    // given
    NSString *name1 = @"\u00C5ron Meister";
    NSString *name2 = @"A\u030Aron Hans";
    NSString *name3 = @"A\u030Aron WhatTheFuck";
    
    // when
    
    ZMDisplayNameGenerator *nameGenerator = [[ZMDisplayNameGenerator alloc] init];

    NSDictionary *map = @{@"A": name1,
                          @"B": name2,
                          @"C": name3};
    
    NSSet *updated = [NSSet set];
    ZMDisplayNameGenerator *newGenerator = [nameGenerator createCopyWithMap:map updatedKeys:&updated];
    
    NSString *displayNameForKey1 = [newGenerator displayNameForKey:@"A"];
    NSString *displayNameForKey2 = [newGenerator displayNameForKey:@"B"];
    NSString *displayNameForKey3 = [newGenerator displayNameForKey:@"C"];
    
    NSString *displayNameForKey4 = [nameGenerator displayNameForKey:@"A"];
    NSString *displayNameForKey5 = [nameGenerator displayNameForKey:@"B"];
    NSString *displayNameForKey6 = [nameGenerator displayNameForKey:@"C"];
    
    NSSet *expectedUpdated = [NSSet setWithArray:@[@"A", @"B", @"C"]];
    
    // then
    XCTAssertEqualObjects(displayNameForKey1, @"\u00C5ron M");
    XCTAssertEqualObjects(displayNameForKey2, @"\u00C5ron H");
    XCTAssertEqualObjects(displayNameForKey3, @"\u00C5ron W");

    NSString *emptyString = @"";
    XCTAssertEqualObjects(displayNameForKey4, emptyString);
    XCTAssertEqualObjects(displayNameForKey5, emptyString);
    XCTAssertEqualObjects(displayNameForKey6, emptyString);

    XCTAssertEqualObjects(updated, expectedUpdated);
}


- (void)testThatItReturnsUpdatedFullNames
{
    // given
    NSString *name1 = @"Hans Meister";
    NSString *name2 = @"Hans Master";

    NSDictionary *map1 = @{@"A": name1};
    NSDictionary *map2 = @{@"A": name2};

    // when
    
    ZMDisplayNameGenerator *nameGenerator = [[ZMDisplayNameGenerator alloc] init];
    nameGenerator.idToFullNameMap = map1;
    
    NSSet *updated = [NSSet set];
    ZMDisplayNameGenerator *newGenerator = [nameGenerator createCopyWithMap:map2 updatedKeys:&updated];
    
    NSString *displayNameForKey1 = [newGenerator displayNameForKey:@"A"];
    NSString *displayNameForKey2 = [nameGenerator displayNameForKey:@"A"];
    
    NSSet *expectedUpdated = [NSSet setWithArray:@[@"A"]];
    
    // then
    XCTAssertEqualObjects(displayNameForKey1, @"Hans");
    XCTAssertEqualObjects(displayNameForKey2, @"Hans");
    
    XCTAssertEqualObjects(updated, expectedUpdated);
}


- (void)testThatItReturnsBothFullNamesWhenBothNamesAreEmptyAfterTrimming
{
    // given
    NSString *name1 = @"******";
    NSString *name2 = @"******";

    // when
    NSDictionary *map1 = @{@"A": name1,
                           @"B": name2};
    
    ZMDisplayNameGenerator *nameGenerator = [[ZMDisplayNameGenerator alloc] init];
    nameGenerator.idToFullNameMap = map1;
    
    NSString *displayNameForKey1 = [nameGenerator displayNameForKey:@"A"];
    NSString *displayNameForKey2 = [nameGenerator displayNameForKey:@"B"];
    
    // then
    XCTAssertEqualObjects(displayNameForKey1, name1);
    XCTAssertEqualObjects(displayNameForKey2, name2);
    
}

- (void)testThatItReturnsInitialsForUser
{
    // given
    NSString *fullName1 = @"Rob A";
    NSString *fullName2 = @"Henry B";
    NSString *fullName3 = @"Arthur The Extreme Superman";
    NSString *fullName4 = @"Kevin ()";
    
    // when
    NSDictionary *map = @{@"A": fullName1,
                          @"B": fullName2,
                          @"C": fullName3,
                          @"D": fullName4};
    
    ZMDisplayNameGenerator *nameGenerator = [[ZMDisplayNameGenerator alloc] init];
    nameGenerator.idToFullNameMap = map;
    
    NSString *initialsForKey1 = [nameGenerator initialsForKey:@"A"];
    NSString *initialsForKey2 = [nameGenerator initialsForKey:@"B"];
    NSString *initialsForKey3 = [nameGenerator initialsForKey:@"C"];
    NSString *initialsForKey4 = [nameGenerator initialsForKey:@"D"];
    
    // then
    XCTAssertEqualObjects(initialsForKey1, @"RA");
    XCTAssertEqualObjects(initialsForKey2, @"HB");
    XCTAssertEqualObjects(initialsForKey3, @"AS");
    XCTAssertEqualObjects(initialsForKey4, @"K");
}

@end
