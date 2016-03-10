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


#import "ZMEncodedNSUUIDWithTimestamp.h"
#import "MessagingTest.h"
#import "ZMConnection+InvitationToConnect.h"
#import "NSURL+LaunchOptions.h"
#import <CommonCrypto/CommonCrypto.h>

static unsigned long SampleTimestamp = 1398634400; // Sun, 27 Apr 2014 21:33:20 GMT
static unsigned long HOUR_IN_SEC = 60 * 60;

@interface ZMEncodedNSUUIDWithTimestampTests : MessagingTest

@end



@implementation ZMEncodedNSUUIDWithTimestampTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (NSData *)randomKey
{
    uint8_t random[kCCKeySizeAES256];
    int success = SecRandomCopyBytes(kSecRandomDefault, kCCKeySizeAES256, random);
    XCTAssert(success == 0);
    return [NSData dataWithBytes:random length:kCCKeySizeAES256];
}

- (void)testThatItInitsFromPlainData
{
    // given
    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:SampleTimestamp];
    NSUUID *uuid = [NSUUID createUUID];
    
    // when
    ZMEncodedNSUUIDWithTimestamp *sut = [[ZMEncodedNSUUIDWithTimestamp alloc] initWithUUID:uuid timestampDate:timestamp encryptionKey:[self randomKey]];
    
    // then
    XCTAssertEqualObjects(sut.timestampDate, timestamp);
    XCTAssertEqualObjects(sut.uuid, uuid);
}

- (void)testThatItCreatesA32BitEncodedRepresentation
{
    // given
    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:SampleTimestamp];
    NSUUID *uuid = [NSUUID createUUID];

    // when
    ZMEncodedNSUUIDWithTimestamp *sut = [[ZMEncodedNSUUIDWithTimestamp alloc] initWithUUID:uuid timestampDate:timestamp encryptionKey:[self randomKey]];
    
    // then
    XCTAssertEqual(sut.encodedData.length, 32u);
}

- (void)testThatEncodedRepresentationsAreDifferentIfTheKeyIsDifferent
{
    // given
    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:SampleTimestamp];
    NSUUID *uuid = [NSUUID createUUID];
    
    // when
    ZMEncodedNSUUIDWithTimestamp *sut1 = [[ZMEncodedNSUUIDWithTimestamp alloc] initWithUUID:uuid timestampDate:timestamp encryptionKey:[self randomKey]];
    ZMEncodedNSUUIDWithTimestamp *sut2 = [[ZMEncodedNSUUIDWithTimestamp alloc] initWithUUID:uuid timestampDate:timestamp encryptionKey:[self randomKey]];
    
    // then
    XCTAssertNotEqualObjects(sut1.encodedData, sut2.encodedData);
}


- (void)testThatEncodedRepresentationsWithSameKeyAndSameDataAreDifferent
{
    // given
    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:SampleTimestamp];
    NSUUID *uuid = [NSUUID createUUID];
    NSData *encryptionKey = [self randomKey];
    
    // when
    ZMEncodedNSUUIDWithTimestamp *sut1 = [[ZMEncodedNSUUIDWithTimestamp alloc] initWithUUID:uuid timestampDate:timestamp encryptionKey:encryptionKey];
    ZMEncodedNSUUIDWithTimestamp *sut2 = [[ZMEncodedNSUUIDWithTimestamp alloc] initWithUUID:uuid timestampDate:timestamp encryptionKey:encryptionKey];
    
    // then
    XCTAssertNotEqualObjects(sut1.encodedData, sut2.encodedData);
}

+ (NSDate *)dateByStrippingMinutesFromDate:(NSDate *)date
{
    return [NSDate dateWithTimeIntervalSince1970:date.timeIntervalSince1970 - (unsigned long) date.timeIntervalSince1970 % HOUR_IN_SEC];
}

- (void)testThatItDecryptsDataCorrectly
{
    // given
    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:SampleTimestamp];
    NSDate *finalTimestamp = [self.class dateByStrippingMinutesFromDate:timestamp];
    NSUUID *uuid = [NSUUID createUUID];
    NSData *encryptionKey = [self randomKey];
    
    // when
    ZMEncodedNSUUIDWithTimestamp *sut1 = [[ZMEncodedNSUUIDWithTimestamp alloc] initWithUUID:uuid timestampDate:timestamp encryptionKey:encryptionKey];
    
    ZMEncodedNSUUIDWithTimestamp *sut2 = [[ZMEncodedNSUUIDWithTimestamp alloc] initWithEncodedData:sut1.encodedData encryptionKey:encryptionKey];
    
    // then
    XCTAssertEqualObjects(sut1.encodedData, sut2.encodedData);
    XCTAssertEqualObjects(sut2.uuid, uuid);
    XCTAssertEqualObjects(sut2.timestampDate, finalTimestamp);
}

@end



@implementation ZMEncodedNSUUIDWithTimestampTests (NSURL)

- (void)testThatItCreatesAndDecodesAURLFromAnEncodedUUIDWithTimestamp
{
    // given
    NSString *prefix = @"https://www.example.com/doo/bar/";
    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:SampleTimestamp];
    NSUUID *uuid = [NSUUID createUUID];
    NSData *encryptionKey = [ZMConnection invitationToConnectEncryptionKey];
    
    ZMEncodedNSUUIDWithTimestamp *original = [[ZMEncodedNSUUIDWithTimestamp alloc] initWithUUID:uuid timestampDate:timestamp encryptionKey:encryptionKey];
    
    // when
    NSURL *url = [original URLWithEncodedUUIDWithTimestampPrefixedWithString:prefix];
    
    // then
    XCTAssertTrue([url.absoluteString hasPrefix:prefix]);
    NSString *token = [url.absoluteString substringFromIndex:prefix.length];

    // when
    ZMEncodedNSUUIDWithTimestamp *decoded = [[ZMEncodedNSUUIDWithTimestamp alloc] initWithSafeBase64EncodedToken:token withEncryptionKey:encryptionKey];
    
    // then
    XCTAssertEqualObjects(decoded.uuid, uuid);
    XCTAssertEqualObjects(decoded.timestampDate, [self.class dateByStrippingMinutesFromDate:timestamp]);
    
}

- (void)testThatItDecodesAURLWithEscapedCharacter_Plus
{
    // given
    NSUUID *expectedUUID = [[NSUUID alloc] initWithUUIDString:@"0F86B28A-85B1-46F4-A387-29D5AB420002"];
    NSURL *url = [NSURL URLWithString:@"wire://connect?code=pq9xgV1-6Gg5xsM_ftz9KTFQkjRZsLbltoN8ATScuDs"];
    NSData *key = [ZMConnection invitationToConnectEncryptionKey];
    NSDate *expiration = [NSDate dateWithTimeIntervalSince1970:SampleTimestamp];
    
    // when
    ZMEncodedNSUUIDWithTimestamp *decoded = [[ZMEncodedNSUUIDWithTimestamp alloc] initWithSafeBase64EncodedToken:[url invitationToConnectToken] withEncryptionKey:key];
    
    // then
    XCTAssertEqualObjects(expectedUUID, decoded.uuid);
    XCTAssertEqualObjects([self.class dateByStrippingMinutesFromDate:expiration], decoded.timestampDate);
}

- (void)testThatItDecodesAURLWithEscapedCharacter_Slash
{
    // given
    NSUUID *expectedUUID = [[NSUUID alloc] initWithUUIDString:@"0F86B28A-85B1-46F4-A387-29D5AB420001"];
    NSURL *url = [NSURL URLWithString:@"wire://connect?code=YjXsjDOfIEMtKPVnlNwHnzmn8J2R7Aika0LVMl1nCnM"];
    NSData *key = [ZMConnection invitationToConnectEncryptionKey];
    NSDate *expiration = [NSDate dateWithTimeIntervalSince1970:SampleTimestamp];
    
    // when
    ZMEncodedNSUUIDWithTimestamp *decoded = [[ZMEncodedNSUUIDWithTimestamp alloc] initWithSafeBase64EncodedToken:[url invitationToConnectToken] withEncryptionKey:key];
    
    // then
    XCTAssertEqualObjects(expectedUUID, decoded.uuid);
    XCTAssertEqualObjects([self.class dateByStrippingMinutesFromDate:expiration], decoded.timestampDate);
}

- (void)testThatItDecodesAURLFromTheAndroidClient
{
    // given
    NSUUID *expectedUUID = [[NSUUID alloc] initWithUUIDString:@"0F86B28A-85B1-46F4-A387-29D5AB420001"];
    NSURL *url = [NSURL URLWithString:@"wire://connect?code=B32C2G-yV4WczFZbSKoLUAkvOvHd_ypNUSiW2WcqVLY"];
    NSData *key = [ZMConnection invitationToConnectEncryptionKey];
    NSDate *expiration = [NSDate dateWithTimeIntervalSince1970:1419349808];
    
    // when
    ZMEncodedNSUUIDWithTimestamp *decoded = [[ZMEncodedNSUUIDWithTimestamp alloc] initWithSafeBase64EncodedToken:[url invitationToConnectToken] withEncryptionKey:key];

    // then
    XCTAssertEqualObjects(expectedUUID, decoded.uuid);
    XCTAssertEqualObjects([self.class dateByStrippingMinutesFromDate:expiration], decoded.timestampDate);
}

- (void)testThatItDoesNotParseURLsWithInvalidData
{
    // given
    NSURL *url = [NSURL URLWithString:@"wire://connect?bogus-key=B32C2G-yV4WczFZbSKoLUAkvOvHd_ypNUSiW2WcqVLY"];
    NSData *key = [ZMConnection invitationToConnectEncryptionKey];
    
    // when
    ZMEncodedNSUUIDWithTimestamp *decoded = [[ZMEncodedNSUUIDWithTimestamp alloc] initWithSafeBase64EncodedToken:[url invitationToConnectToken] withEncryptionKey:key];
    
    // then
    XCTAssertNil(decoded);
}

@end

