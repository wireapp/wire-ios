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

@import XCTest;
@import OCMock;

#import "NSUserDefaults+SharedUserDefaults.h"

@interface NSUserDefaults_SharedUserDefaultsTests : XCTestCase

@end

@implementation NSUserDefaults_SharedUserDefaultsTests

- (void)testThatItReturnsNilFromGroupNameIfNoWireGroupIdInInfoPlist
{
#if !TARGET_OS_IPHONE
    XCTAssertNil([NSUserDefaults groupName]);
#else
    NSMutableDictionary *infoPlist = [[[NSBundle mainBundle] infoDictionary] mutableCopy];
    [infoPlist removeObjectForKey:@"WireGroupId"];
    id mockBundle = [OCMockObject partialMockForObject:[NSBundle mainBundle]];
    [[[mockBundle stub] andReturn:infoPlist] infoDictionary];
    XCTAssertNil([NSUserDefaults groupName]);
    [mockBundle stopMocking];
#endif
}

- (void)testThatItReturnsExpectedGroupName
{
#if TARGET_OS_IPHONE
    NSMutableDictionary *infoPlist = [[[NSBundle mainBundle] infoDictionary] mutableCopy];
    infoPlist[@"WireGroupId"] = @"test.bundle.id";
    id mockBundle = [OCMockObject partialMockForObject:[NSBundle mainBundle]];
    [[[mockBundle stub] andReturn:infoPlist] infoDictionary];
    XCTAssertEqualObjects([NSUserDefaults groupName], @"group.test.bundle.id");
    [mockBundle stopMocking];
#endif
}

- (void)testThatItReturnsExpectedUserDefaults
{
#if TARGET_OS_IPHONE
    NSMutableDictionary *infoPlist = [[[NSBundle mainBundle] infoDictionary] mutableCopy];
    infoPlist[@"WireGroupId"] = @"com.wearezeta.zclient-alpha";
    id mockBundle = [OCMockObject partialMockForObject:[NSBundle mainBundle]];
    [[[mockBundle stub] andReturn:infoPlist] infoDictionary];

#endif
    
    //given
    NSUserDefaults *defaults = [NSUserDefaults sharedUserDefaults];
    NSString *groupName = [NSUserDefaults groupName];
    NSUserDefaults *testDefaults = [[NSUserDefaults alloc] initWithSuiteName:groupName];

    //when
    NSString *expectedValue = @"value";
    [testDefaults setObject:expectedValue forKey:@"test"];
    [testDefaults synchronize];

    //then
    NSString *value = [defaults valueForKey:@"test"];
    XCTAssertEqualObjects(value, expectedValue);
   
#if TARGET_OS_IPHONE
    [mockBundle stopMocking];
#endif
}


@end
