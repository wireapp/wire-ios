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


@interface CBBasicCryptoTest : CBTestCase

@property (nonatomic) CBCryptoBox *aliceBox;
@property (nonatomic) CBCryptoBox *bobBox;

@end

@implementation CBBasicCryptoTest

- (void)testThatBasicTestCanRun
{
    self.aliceBox = [self createBoxAndCheckAsserts:@"alice"];
    self.bobBox = [self createBoxAndCheckAsserts:@"bob"];
    
    CBPreKey *bobPreKey = [self generatePreKeyAndCheckAssertsWithLocation:1 box:self.bobBox];
    
    //Alice side
    NSError *error = nil;
    CBSession *aliceToBobSession = [self.aliceBox sessionWithId:@"sessionWithBob" fromPreKey:bobPreKey error:&error];
    XCTAssertNil(error, @"Error is not nil");
    XCTAssertNotNil(aliceToBobSession, @"Session creation from prekey failed");
    
    [aliceToBobSession save:&error];
    XCTAssertNil(error, @"Error is not nil");
    
    // Encrypt a message from alice to bob
    NSString *const plain = @"Hello Bob!";
    NSData *plainData = [plain dataUsingEncoding:NSUTF8StringEncoding];
    NSData *cipherData = [aliceToBobSession encrypt:plainData error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(cipherData);
    XCTAssertNotEqual(plainData, cipherData);
    
    //Bob's side
    CBSessionMessage *bobToAliceSessionMessage = [self.bobBox sessionMessageWithId:@"sessionToAlice" fromMessage:cipherData error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(bobToAliceSessionMessage);
    XCTAssertNotNil(bobToAliceSessionMessage.session);
    XCTAssertNotNil(bobToAliceSessionMessage.data);
    
    CBSession *bobToAliceSession = bobToAliceSessionMessage.session;

    [bobToAliceSession save:&error];
    XCTAssertNil(error);
    
    NSString *decrypted = [[NSString alloc] initWithData:bobToAliceSessionMessage.data encoding:NSUTF8StringEncoding];
    XCTAssertTrue([plain isEqualToString:decrypted]);

    // Compare fingerprints
    NSData *localFingerprint = [self.aliceBox localFingerprint:&error];
    XCTAssertNil(error);
    NSData *remoteFingerprint = [bobToAliceSession remoteFingerprint];
    XCTAssertNotNil(localFingerprint);
    XCTAssertNotNil(remoteFingerprint);
    XCTAssertEqualObjects(localFingerprint, remoteFingerprint);

    localFingerprint = nil;
    remoteFingerprint = nil;
    
    localFingerprint = [self.bobBox localFingerprint:&error];
    XCTAssertNil(error);
    remoteFingerprint = [aliceToBobSession remoteFingerprint];
    XCTAssertNotNil(localFingerprint);
    XCTAssertNotNil(remoteFingerprint);
    XCTAssertEqualObjects(localFingerprint, remoteFingerprint);
    
    [self.aliceBox closeSession:aliceToBobSession];
    [self.bobBox closeSession:bobToAliceSession];
    
    aliceToBobSession = [self.aliceBox sessionById:@"sessionWithBob" error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(aliceToBobSession);
    
    bobToAliceSession = [self.bobBox sessionById:@"sessionToAlice" error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(bobToAliceSession);
}

- (void)testThatSessionCanNotBeUseToDecryptWhenSaved;
{
    self.aliceBox = [self createBoxAndCheckAsserts:@"alice"];
    self.bobBox = [self createBoxAndCheckAsserts:@"bob"];
    
    CBPreKey *bobPreKey = [self generatePreKeyAndCheckAssertsWithLocation:1 box:self.bobBox];
    
    //Alice side
    NSError *error = nil;
    CBSession *aliceToBobSession = [self.aliceBox sessionWithId:@"sessionWithBob" fromPreKey:bobPreKey error:&error];
    XCTAssertNil(error, @"Error is not nil");
    XCTAssertNotNil(aliceToBobSession, @"Session creation from prekey failed");
    
    [aliceToBobSession save:&error];
    XCTAssertNil(error, @"Error is not nil");
    
    // Encrypt a message from alice to bob
    NSString *const plain = @"Hello Bob!";
    NSData *plainData = [plain dataUsingEncoding:NSUTF8StringEncoding];
    NSData *cipherData = [aliceToBobSession encrypt:plainData error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(cipherData);
    XCTAssertNotEqual(plainData, cipherData);
    
    //Bob's side
    CBSessionMessage *bobToAliceSessionMessage = [self.bobBox sessionMessageWithId:@"sessionToAlice" fromMessage:cipherData error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(bobToAliceSessionMessage);
    XCTAssertNotNil(bobToAliceSessionMessage.session);
    XCTAssertNotNil(bobToAliceSessionMessage.data);
    
    CBSession *bobToAliceSession = bobToAliceSessionMessage.session;
    [bobToAliceSession save:&error];
    
    //alice again
    NSString *const plain2 = @"Answer me, Bob!";
    NSData *plainData2 = [plain2 dataUsingEncoding:NSUTF8StringEncoding];
    NSData *cipherData2 = [aliceToBobSession encrypt:plainData2 error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(cipherData2);
    XCTAssertNotEqual(plainData2, cipherData2);

    //Bob's return
    NSData *newMessage = [bobToAliceSession decrypt:cipherData2 error:&error];
    
    XCTAssertNil(error);
    XCTAssertNotNil(newMessage);
    XCTAssertEqualObjects(plainData2, newMessage);
    
    [self.bobBox setSessionToRequireSave:bobToAliceSession];
    [self.bobBox saveSessionsRequiringSave];
    
    [self.bobBox close];
    self.bobBox = [self createBoxAndCheckAsserts:@"bob"];
    
    CBSession *session = [self.bobBox sessionById:@"sessionToAlice" error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(session);
    
    NSData *anotherNewData = [session decrypt:cipherData2 error:&error];
    XCTAssertNotNil(error);
    XCTAssertNil(anotherNewData);
}

- (void)testThatSessionCanStillBeUseToDecryptIfNotSaved;
{
    self.aliceBox = [self createBoxAndCheckAsserts:@"alice"];
    self.bobBox = [self createBoxAndCheckAsserts:@"bob"];
    
    CBPreKey *bobPreKey = [self generatePreKeyAndCheckAssertsWithLocation:1 box:self.bobBox];
    
    //Alice side
    NSError *error = nil;
    CBSession *aliceToBobSession = [self.aliceBox sessionWithId:@"sessionWithBob" fromPreKey:bobPreKey error:&error];
    XCTAssertNil(error, @"Error is not nil");
    XCTAssertNotNil(aliceToBobSession, @"Session creation from prekey failed");
    
    [aliceToBobSession save:&error];
    XCTAssertNil(error, @"Error is not nil");
    
    // Encrypt a message from alice to bob
    NSString *const plain = @"Hello Bob!";
    NSData *plainData = [plain dataUsingEncoding:NSUTF8StringEncoding];
    NSData *cipherData = [aliceToBobSession encrypt:plainData error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(cipherData);
    XCTAssertNotEqual(plainData, cipherData);
    
    //Bob's side
    CBSessionMessage *bobToAliceSessionMessage = [self.bobBox sessionMessageWithId:@"sessionToAlice" fromMessage:cipherData error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(bobToAliceSessionMessage);
    XCTAssertNotNil(bobToAliceSessionMessage.session);
    XCTAssertNotNil(bobToAliceSessionMessage.data);
    
    CBSession *bobToAliceSession = bobToAliceSessionMessage.session;
    [bobToAliceSession save:&error];
    
    //alice again
    NSString *const plain2 = @"Answer me, Bob!";
    NSData *plainData2 = [plain2 dataUsingEncoding:NSUTF8StringEncoding];
    NSData *cipherData2 = [aliceToBobSession encrypt:plainData2 error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(cipherData2);
    XCTAssertNotEqual(plainData2, cipherData2);
    
    //Bob's return
    NSData *newMessage = [bobToAliceSession decrypt:cipherData2 error:&error];
    
    XCTAssertNil(error);
    XCTAssertNotNil(newMessage);
    XCTAssertEqualObjects(plainData2, newMessage);
    
    [self.bobBox setSessionToRequireSave:bobToAliceSession];
    [self.bobBox resetSessionsRequiringSave];
    [self.bobBox saveSessionsRequiringSave];
    
    [self.bobBox close];
    self.bobBox = [self createBoxAndCheckAsserts:@"bob"];
    
    CBSession *session = [self.bobBox sessionById:@"sessionToAlice" error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(session);
    
    NSData *anotherNewData = [session decrypt:cipherData2 error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(anotherNewData);
    XCTAssertEqualObjects(plainData2, anotherNewData);
}

@end
