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


@interface CBLastPreKeyTest : CBTestCase

@end

@implementation CBLastPreKeyTest

- (void)testThatLastPrekeyTestCanRun
{
    CBCryptoBox *aliceBox = [self createBoxAndCheckAsserts:@"alice"];
    CBCryptoBox *bobBox = [self createBoxAndCheckAsserts:@"bob"];

    NSError *error = nil;
    CBPreKey *bobLastPreKey = [bobBox lastPreKey:&error];
    XCTAssertNotNil(bobLastPreKey);
    XCTAssertNil(error);
    
    CBSession *aliceSession = [aliceBox sessionWithId:@"alice" fromPreKey:bobLastPreKey error:&error];
    XCTAssertNotNil(aliceSession);
    XCTAssertNil(error);
    
    const NSString *plain = @"Hello Bob!";
    NSData *plainData = [plain dataUsingEncoding:NSUTF8StringEncoding];
    NSData *cipherData = [aliceSession encrypt:plainData error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(cipherData);
    
                               
    CBSession *bobSession = nil;
    CBSessionMessage *bobSessionMessage = [bobBox sessionMessageWithId:@"bob" fromMessage:cipherData error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(bobSessionMessage);
    XCTAssertNotNil(bobSessionMessage.session);
    XCTAssertNotNil(bobSessionMessage.data);

    bobSession = bobSessionMessage.session;
    NSString *decrypted = [[NSString alloc] initWithData:bobSessionMessage.data encoding:NSUTF8StringEncoding];
    XCTAssertTrue([plain isEqualToString:decrypted]);
    
    [bobSession save:&error];
    XCTAssertNil(error);
    [bobBox closeSession:bobSession];
    bobSession = nil;
    decrypted = nil;
    
    // Bob's last prekey is not removed
    bobSessionMessage = [bobBox sessionMessageWithId:@"bob" fromMessage:cipherData error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(bobSessionMessage);
    decrypted = [[NSString alloc] initWithData:bobSessionMessage.data encoding:NSUTF8StringEncoding];
    XCTAssertTrue([plain isEqualToString:decrypted]);
    
    NSLog(@"%s test_last_prekey finished", __PRETTY_FUNCTION__);
}

@end
