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


@import XCTest;
@import WireUtilities;

@interface ZMStringLengthValidatorTests : XCTestCase

@end

@implementation ZMStringLengthValidatorTests

- (void)testThatTooShortStringsDoNotPassValidation
{
    NSString *value = @"short";
    NSError *error;
    BOOL result = [StringLengthValidator validateValue:&value minimumStringLength:15 maximumStringLength:100 maximumByteLength:100 error:&error];
    XCTAssertFalse(result);
    XCTAssertNotNil(error);
}

- (void)testThatTooLongStringsDoNotPassValidation
{
    NSString *value = @"long";
    NSError *error;
    BOOL result = [StringLengthValidator validateValue:&value minimumStringLength:1 maximumStringLength:3 maximumByteLength:100 error:&error];
    XCTAssertFalse(result);
    XCTAssertNotNil(error);
}

- (void)testThatValidStringsPassValidation
{
    NSString *value = @"normal";
    NSError *error;
    BOOL result = [StringLengthValidator validateValue:&value minimumStringLength:1 maximumStringLength:10 maximumByteLength:100 error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
}

- (void)testThatCombinedEmojiPassesValidation_3
{
    const NSString *originalValue = @"👨‍👧‍👦";
    NSString *value = originalValue.copy;
    NSError *error;
    BOOL result = [StringLengthValidator validateValue:&value minimumStringLength:1 maximumStringLength:64 maximumByteLength:100 error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
    XCTAssertEqualObjects(originalValue, value);
}

- (void)testThatCombinedEmojiPassesValidation_4
{
    const NSString *originalValue = @"👩‍👩‍👦‍👦";
    NSString *value = originalValue.copy;
    NSError *error;
    BOOL result = [StringLengthValidator validateValue:&value minimumStringLength:1 maximumStringLength:64 maximumByteLength:100 error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
    XCTAssertEqualObjects(originalValue, value);
}

- (void)testThatItRemovesControlCharactersBetweenCombinedEmoji
{
    const NSString *originalValue = @"👩‍👩‍👦‍👦/n👨‍👧‍👦";
    NSString *value = originalValue.copy;
    NSError *error;
    BOOL result = [StringLengthValidator validateValue:&value minimumStringLength:1 maximumStringLength:64 maximumByteLength:100 error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
    XCTAssertEqualObjects(originalValue, value);
}

- (void)testThatNilIsNotValid
{
    NSString *value = nil;
    NSError *error;
    BOOL result = [StringLengthValidator validateValue:&value minimumStringLength:1 maximumStringLength:10 maximumByteLength:100 error:&error];
    XCTAssertFalse(result);
    XCTAssertNotNil(error);
}

- (void)testThatItReplacesNewlinesAndTabWithSpacesInThePhoneNumber;
{
    // given
    NSString *phoneNumber = @"1234\n5678";
    NSError *error;
    
    // when
    [StringLengthValidator validateValue:&phoneNumber minimumStringLength:0 maximumStringLength:20 maximumByteLength:100 error:&error];
    
    // then
    XCTAssertNil(error);
    XCTAssertEqualObjects(phoneNumber, @"1234 5678");
}

@end
