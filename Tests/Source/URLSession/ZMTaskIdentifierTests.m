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
@import OCMock;
#import "ZMTaskIdentifier.h"


@interface ZMTaskIdentifierTests : ZMTBaseTest
@end


@implementation ZMTaskIdentifierTests

- (void)testThatItCreatesAnIdentifier {
    // given
    ZMTaskIdentifier *sut = [ZMTaskIdentifier identifierWithIdentifier:46];
    
    // then
    XCTAssertEqual(sut.identifier, 46lu);
}

- (void)testThatTwoEqualTaskIdentifierObjectsAreConsideredEqual {
    // given
    ZMTaskIdentifier *first = [ZMTaskIdentifier identifierWithIdentifier:46];
    ZMTaskIdentifier *second = [ZMTaskIdentifier identifierWithIdentifier:46];
    
    // then
    XCTAssertEqualObjects(first, second);
}

- (void)testThatTwoDifferentTaskIdentifierObjectsAreNotConsideredEqual {
    // given
    ZMTaskIdentifier *first = [ZMTaskIdentifier identifierWithIdentifier:46];
    ZMTaskIdentifier *second = [ZMTaskIdentifier identifierWithIdentifier:100];
    ZMTaskIdentifier *third = [ZMTaskIdentifier identifierWithIdentifier:12];
    
    // then
    XCTAssertNotEqualObjects(first, second);
    XCTAssertNotEqualObjects(first, third);
    XCTAssertNotEqualObjects(second, third);
}

- (void)testThatItCanBeSerializedAndDeserializedFromAndToNSData {
    // given
    ZMTaskIdentifier *sut = [ZMTaskIdentifier identifierWithIdentifier:46];
    XCTAssertNotNil(sut);
    
    // when
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:sut];
    XCTAssertNotNil(data);
    
    // then
    ZMTaskIdentifier *deserializedSut = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    XCTAssertNotNil(deserializedSut);
    XCTAssertEqualObjects(deserializedSut, sut);
}

- (void)testThatItCanBeInitializedFromDataAndReturnsTheCorrectData {
    // given
    ZMTaskIdentifier *sut = [ZMTaskIdentifier identifierWithIdentifier:42];
    XCTAssertNotNil(sut);
    
    // when
    NSData *data = sut.data;
    XCTAssertNotNil(data);
    
    // then
    ZMTaskIdentifier *deserializedSut = [ZMTaskIdentifier identifierFromData:data];
    XCTAssertNotNil(deserializedSut);
    XCTAssertEqualObjects(deserializedSut, sut);
}

@end
