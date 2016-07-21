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


#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "CBTestCase.h"

@import Cryptobox;



@interface CBPreKeyRemovalTest : CBTestCase

@end

@implementation CBPreKeyRemovalTest


- (void)disabled_testExample
{
    CBCryptoBox *aliceBox = [self createBoxAndCheckAsserts:@"alice"];
    CBCryptoBox *bobBox = [self createBoxAndCheckAsserts:@"bob"];
    
    
    CBPreKey *bobPreKey = [self generatePreKeyAndCheckAssertsWithLocation:1 box:bobBox];
    
    NSError *error = nil;
    CBSession *aliceSession = [aliceBox sessionWithId:@"alice" fromPreKey:bobPreKey error:&error];
    XCTAssertNotNil(aliceSession);
    XCTAssertNil(error);
    
    NSString *const plain = @"Hello Bob!";
    NSData *plainData = [plain dataUsingEncoding:NSUTF8StringEncoding];
    NSData *cipher = [aliceSession encrypt:plainData error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(cipher);
    
    CBSessionMessage *bobSessionMessage = [bobBox sessionMessageWithId:@"bob" fromMessage:cipher error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(bobSessionMessage);
    XCTAssertNotNil(bobSessionMessage.data);
    XCTAssertNotNil(bobSessionMessage.session);
    
    CBSession *bobSession = bobSessionMessage.session;
    
    // Pretend something happened before Bob could save his session and he retries.
    // The prekey should not be removed (yet).
    [bobBox closeSession:bobSession];    
    bobSessionMessage = nil;
    
    bobSessionMessage = [bobBox sessionMessageWithId:@"bob" fromMessage:cipher error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(bobSessionMessage);
    XCTAssertNotNil(bobSessionMessage.data);
    XCTAssertNotNil(bobSessionMessage.session);
    
    bobSession = bobSessionMessage.session;
    [bobSession save:&error];
    XCTAssertNil(error);
    
    // Now the prekey should be gone
//    [bobBox closeSession:bobSession];

    // TODO: Figure out how to handle NSAssert's and the exception handler call
//    bobSessionMessage = [bobBox sessionMessageWithId:@"bob" fromMessage:cipher error:&error];
//    XCTAssertNotNil(error);
//    XCTAssertTrue(error.code == CBErrorCodeInvalidMessage);
}


@end
