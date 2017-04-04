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


@import WireTesting;
@import WireProtos;
@import WireUtilities;
@import WireDataModel;


@interface ZMGenericMessage_ExternalTests : ZMTBaseTest

@property (nonatomic, nonnull) ZMGenericMessage *sut;

@end


@implementation ZMGenericMessage_ExternalTests

- (void)setUp {
    [super setUp];
    ZMGenericMessageBuilder *builder = ZMGenericMessage.builder;
    ZMTextBuilder *textBuilder = ZMText.builder;
    textBuilder.content = @"She sells sea shells";
    builder.text = textBuilder.build;
    builder.messageId = NSUUID.createUUID.transportString;
    self.sut = builder.build;
    XCTAssertTrue(self.sut.hasText);
}

- (void)testThatItEncryptsTheMessageAndReturnsTheCorrectKeyAndDigest
{
    // given & when
    ZMExternalEncryptedDataWithKeys *dataWithKeys = [ZMGenericMessage encryptedDataWithKeysFromMessage:self.sut];
    XCTAssertNotNil(dataWithKeys);
    
    ZMEncryptionKeyWithChecksum *keysWithDigest = dataWithKeys.keys;
    NSData *data = dataWithKeys.data;
    
    // then
    XCTAssertEqualObjects(data.zmSHA256Digest, keysWithDigest.sha256);
    XCTAssertEqualObjects([data zmDecryptPrefixedPlainTextIVWithKey:keysWithDigest.aesKey], self.sut.data);
}

- (void)testThatItUsesADifferentKeyForEachCall
{
    // given & when
    ZMExternalEncryptedDataWithKeys *firstDataWithKeys = [ZMGenericMessage encryptedDataWithKeysFromMessage:self.sut];
    ZMExternalEncryptedDataWithKeys *secondDataWithKeys = [ZMGenericMessage encryptedDataWithKeysFromMessage:self.sut];

    // then
    XCTAssertNotEqualObjects(firstDataWithKeys.keys.aesKey, secondDataWithKeys.keys.aesKey);
    XCTAssertNotEqualObjects(firstDataWithKeys, secondDataWithKeys);
    NSData *firstEncrypted = [firstDataWithKeys.data zmDecryptPrefixedPlainTextIVWithKey:firstDataWithKeys.keys.aesKey];
    NSData *secondEncrypted = [secondDataWithKeys.data zmDecryptPrefixedPlainTextIVWithKey:secondDataWithKeys.keys.aesKey];
    
    XCTAssertEqualObjects(firstEncrypted, self.sut.data);
    XCTAssertEqualObjects(secondEncrypted, self.sut.data);
}

- (void)testThatDifferentKeysAreNotConsideredEqual
{
    // given & when
    ZMEncryptionKeyWithChecksum *firstKeys = [ZMGenericMessage encryptedDataWithKeysFromMessage:self.sut].keys;
    ZMEncryptionKeyWithChecksum *secondKeys = [ZMGenericMessage encryptedDataWithKeysFromMessage:self.sut].keys;
    
    // then
    XCTAssertFalse([firstKeys.aesKey isEqualToData:secondKeys.aesKey]);
    XCTAssertFalse([firstKeys.sha256 isEqualToData:secondKeys.sha256]);
    XCTAssertEqualObjects(firstKeys, firstKeys);
    XCTAssertNotEqualObjects(firstKeys, secondKeys);
}

@end
