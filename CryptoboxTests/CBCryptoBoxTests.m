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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "CBTestCase.h"

@import Cryptobox;

@interface CBCryptoBoxTests : CBTestCase

@property (nonatomic) CBCryptoBox *box;

@end

@implementation CBCryptoBoxTests

- (void)setUp
{
    [super setUp];
    
    self.box = [self createBoxAndCheckAsserts:self.name];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testThatPreKeysAreGettingGenerated
{
    NSRange range = (NSRange){0, 10};
    NSError *error = nil;
    NSArray *preKeys = [self.box generatePreKeys:range error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(preKeys);
    XCTAssertEqual(preKeys.count, range.length);
}

- (void)testThatPreKeysGenerationErrorHandlingRespectsMaxLength
{
    NSRange range = (NSRange){0, CBMaxPreKeyID + 1};
    NSError *error = nil;
    
    XCTAssertThrowsSpecificNamed([self.box generatePreKeys:range error:&error], NSException, NSInvalidArgumentException, @"Should throw an invalid argument exception");
}

- (void)testThatPreKeysGenerationErrorHandlingChecksLocation
{
    // Should pass
    NSRange range = (NSRange){CBMaxPreKeyID, 1};
    NSError *error = nil;
    NSArray *preKeys = [self.box generatePreKeys:range error:&error];
#pragma unused(preKeys)
    XCTAssertNil(error);
    XCTAssertNotNil(preKeys);
    
    // Shouldn't pass
    range = (NSRange){CBMaxPreKeyID + 1, 1};
    XCTAssertThrowsSpecificNamed([self.box generatePreKeys:range error:&error], NSException, NSInvalidArgumentException, @"Should throw an invalid argument exception");
}

- (void)testThatPreKeysGenerationErrorHandlingChecksLength
{
    // Invalid input, no keys to generate
    NSRange range = (NSRange){0, 0};
    NSError *error = nil;
    
    XCTAssertThrowsSpecificNamed([self.box generatePreKeys:range error:&error], NSException, NSInvalidArgumentException, @"Should throw an invalid argument exception");
    
    // Out of max bounds
    range = (NSRange){0, CBMaxPreKeyID + 1};
    XCTAssertThrowsSpecificNamed([self.box generatePreKeys:range error:&error], NSException, NSInvalidArgumentException, @"Should throw an invalid argument exception");
}

- (void)testThatLastPreKeyReturnsPreKey
{
    NSError *error = nil;
    CBPreKey *preKey = [self.box lastPreKey:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(preKey);
}

- (void)testThatItCreatesSessionFromPreKey
{
    CBCryptoBox *aliceBox = [self createBoxAndCheckAsserts:@"alice"];
    CBCryptoBox *bobBox = [self createBoxAndCheckAsserts:@"bob"];
    
    CBPreKey *bobPreKey = [self generatePreKeyAndCheckAssertsWithLocation:1 box:bobBox];
    
    //Alice side
    NSError *error = nil;
    CBSession *aliceToBobSession = [aliceBox sessionWithId:@"sessionWithBob" fromPreKey:bobPreKey error:&error];
    XCTAssertNil(error, @"Error is not nil");
    XCTAssertNotNil(aliceToBobSession, @"Session creation from prekey failed");
}

- (void)testThatItCreatesSessionFromStringPreKey
{
    CBCryptoBox *aliceBox = [self createBoxAndCheckAsserts:@"alice"];
    CBCryptoBox *bobBox = [self createBoxAndCheckAsserts:@"bob"];
    
    CBPreKey *bobPreKey = [self generatePreKeyAndCheckAssertsWithLocation:1 box:bobBox];
    NSString *bobBase64StringKey = [bobPreKey.data base64EncodedStringWithOptions:0];
    
    //Alice side
    NSError *error = nil;
    CBSession *aliceToBobSession = [aliceBox sessionWithId:@"sessionWithBob" fromStringPreKey:bobBase64StringKey error:&error];
    XCTAssertNil(error, @"Error is not nil");
    XCTAssertNotNil(aliceToBobSession, @"Session creation from prekey failed");
}

@end
