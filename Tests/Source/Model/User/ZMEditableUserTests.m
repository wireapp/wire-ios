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


@import WireTransport;
@import WireDataModel;

#import "ZMBaseManagedObjectTest.h"
#import "ZMEditableUser.h"

@interface ZMEditableUserTests : ZMBaseManagedObjectTest

@end

@implementation ZMEditableUserTests

- (void)testThatItValidatesTheUserName
{
    // given
    ZMIncompleteRegistrationUser *user = [[ZMIncompleteRegistrationUser alloc] init];
    NSString *validName = @"Maria";
    NSMutableString *longName = [@"Mario" mutableCopy];
    for(int i = 0; i < 200; ++i) {
        [longName appendString:@"o"];
    }
    NSString *shortName = @"M";
    
    // when
    XCTAssertTrue([user validateValue:&validName forKey:@"name" error:nil]);
    XCTAssertFalse([user validateValue:&longName forKey:@"name" error:nil]);
    XCTAssertFalse([user validateValue:&shortName forKey:@"name" error:nil]);
    
}


- (void)testThatItValidatesTheAccentColor
{
    // given
    ZMIncompleteRegistrationUser *user = [[ZMIncompleteRegistrationUser alloc] init];
    NSNumber *validAccentColor = @(ZMAccentColorBrightYellow);
    NSNumber *invalidAccentColor = @(100000);
    
    // when
    XCTAssertTrue([user validateValue:&validAccentColor forKey:@"accentColorValue" error:nil]);
    
    [user validateValue:&invalidAccentColor forKey:@"accentColorValue" error:nil];
    XCTAssertLessThanOrEqual(invalidAccentColor.integerValue, ZMAccentColorMax);
    XCTAssertGreaterThanOrEqual(invalidAccentColor.integerValue, ZMAccentColorMin);
}

- (void)testThatItValidatesTheEmail
{
    // given
    ZMIncompleteRegistrationUser *user = [[ZMIncompleteRegistrationUser alloc] init];
    NSString *validEmail = @"anette@foo.bar";
    NSString *invalidEmail = @"kathrine@";
    
    // when
    XCTAssertTrue([user validateValue:&validEmail forKey:@"emailAddress" error:nil]);
    XCTAssertFalse([user validateValue:&invalidEmail forKey:@"emailAddress" error:nil]);
}

- (void)testThatItValidatesThePhoneNumber
{
    // given
    ZMIncompleteRegistrationUser *user = [[ZMIncompleteRegistrationUser alloc] init];
    NSString *validPhone = @"+4912345678";
    NSMutableString *invalidPhone = [@"+49" mutableCopy];
    for(int i = 0; i < 100; ++i) {
        [invalidPhone appendString:@"0"];
    }
    
    // when
    XCTAssertTrue([user validateValue:&validPhone forKey:@"phoneNumber" error:nil]);
    XCTAssertFalse([user validateValue:&invalidPhone forKey:@"phoneNumber" error:nil]);
}

- (void)testThatItDoesNotValidateAPhoneNumberWithLettersTheRightError
{
    // given
    ZMIncompleteRegistrationUser *user = [[ZMIncompleteRegistrationUser alloc] init];
    NSString *phoneWithLetters = @"+49abcdefg";
    NSString *shortPhoneWithLetters = @"ab";
    
    NSError *error;
    
    // when
    XCTAssertFalse([user validateValue:&phoneWithLetters forKey:@"phoneNumber" error:&error]);
    XCTAssertEqualObjects(error.domain, ZMObjectValidationErrorDomain);
    XCTAssertEqual(error.code, (long) ZMObjectValidationErrorCodePhoneNumberContainsInvalidCharacters);
    
    // and when
    XCTAssertFalse([user validateValue:&shortPhoneWithLetters forKey:@"phoneNumber" error:&error]);
    XCTAssertEqualObjects(error.domain, ZMObjectValidationErrorDomain);
    XCTAssertEqual(error.code, (long) ZMObjectValidationErrorCodePhoneNumberContainsInvalidCharacters);
}

- (void)testThatItDoesNotValidateAShortPhoneNumberWithTheRightError
{
    // given
    ZMIncompleteRegistrationUser *user = [[ZMIncompleteRegistrationUser alloc] init];
    NSString *shortPhone = @"+49";
    
    NSError *error;
    
    // when
    XCTAssertFalse([user validateValue:&shortPhone forKey:@"phoneNumber" error:&error]);
    XCTAssertEqualObjects(error.domain, ZMObjectValidationErrorDomain);
    XCTAssertEqual(error.code, (long) ZMObjectValidationErrorCodeStringTooShort);
}


- (void)testThatItDoesNotValidateALongPhoneNumberWithTheRightError
{
    // given
    ZMIncompleteRegistrationUser *user = [[ZMIncompleteRegistrationUser alloc] init];
    NSString *shortPhone = @"+4900000002132131241241234234";
    
    NSError *error;
    
    // when
    XCTAssertFalse([user validateValue:&shortPhone forKey:@"phoneNumber" error:&error]);
    XCTAssertEqualObjects(error.domain, ZMObjectValidationErrorDomain);
    XCTAssertEqual(error.code, (long) ZMObjectValidationErrorCodeStringTooLong);
}

@end



@implementation ZMEditableUserTests (ZMCompleteRegistrationUser)

- (void)testThatItNormalizesThePhoneNumber
{
    // given
    NSString *code = @"aabbcc";
    NSString *phoneNumber = @"+49(123)45.6-78";
    NSString *normalizedPhoneNumber = [phoneNumber copy];
    [ZMPhoneNumberValidator validateValue:&normalizedPhoneNumber error:nil];
    
    // when
    ZMCompleteRegistrationUser *sut = [ZMCompleteRegistrationUser registrationUserWithPhoneNumber:phoneNumber phoneVerificationCode:code];
    
    // then
    XCTAssertEqualObjects(sut.phoneNumber, normalizedPhoneNumber);
    XCTAssertEqualObjects(sut.phoneVerificationCode, code);
    XCTAssertNotEqualObjects(normalizedPhoneNumber, phoneNumber, @"Should not have modified original");
}

- (void)testThatItNormalizesThePhoneNumberWhenSwitchingFromIncompleteToComplete
{
    // given
    NSString *code = @"aabbcc";
    NSString *phoneNumber = @"+49(123)45.6-78";
    NSString *normalizedPhoneNumber = [phoneNumber copy];
    [ZMPhoneNumberValidator validateValue:&normalizedPhoneNumber error:nil];
    ZMIncompleteRegistrationUser *user = [[ZMIncompleteRegistrationUser alloc] init];
    user.phoneNumber = phoneNumber;
    user.phoneVerificationCode = code;
    
    // when
    ZMCompleteRegistrationUser *sut = [user completeRegistrationUser];
    
    // then
    XCTAssertEqualObjects(sut.phoneNumber, normalizedPhoneNumber);
    XCTAssertEqualObjects(sut.phoneVerificationCode, code);
    XCTAssertNotEqualObjects(normalizedPhoneNumber, phoneNumber, @"Should not have modified original");
    XCTAssertEqualObjects(user.phoneNumber, phoneNumber, @"Should not have modified incomplete user");

}

- (void)testThatItNormalizesTheEmailAddressWhenSwitchingFromIncompleteToComplete
{
    // given
    NSString *password = @"aabbcc";
    NSString *emailAddress = @" john.doe@gmail.com ";
    NSString *normalizedEmailAddress = [emailAddress copy];
    [ZMEmailAddressValidator validateValue:&normalizedEmailAddress error:nil];
    ZMIncompleteRegistrationUser *user = [[ZMIncompleteRegistrationUser alloc] init];
    user.emailAddress = emailAddress;
    user.password = password;
    
    // when
    ZMCompleteRegistrationUser *sut = [user completeRegistrationUser];
    
    // then
    XCTAssertEqualObjects(sut.emailAddress, normalizedEmailAddress);
    XCTAssertEqualObjects(sut.password, password);
    XCTAssertNotEqualObjects(normalizedEmailAddress, emailAddress, @"Should not have modified original");
    XCTAssertEqualObjects(user.emailAddress, emailAddress, @"Should not have modified incomplete user");
    
}

@end
