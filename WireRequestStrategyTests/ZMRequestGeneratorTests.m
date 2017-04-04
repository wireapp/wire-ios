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
@import WireTesting;

#import "ZMRequestGenerator.h"



@interface FakeRequestGenerator : NSObject <ZMRequestGenerator>

@property (nonatomic) ZMTransportRequest *nextRequest;

@end



@implementation FakeRequestGenerator
@end



@interface ZMRequestGeneratorTests : ZMTBaseTest

@property (nonatomic) ZMTransportRequest *requestA;
@property (nonatomic) ZMTransportRequest *requestB;
@property (nonatomic) FakeRequestGenerator *generatorA;
@property (nonatomic) FakeRequestGenerator *generatorB;

@end



@implementation ZMRequestGeneratorTests

- (void)setUp
{
    [super setUp];
    self.requestA = [ZMTransportRequest requestGetFromPath:@"/foo/A"];
    self.requestB = [ZMTransportRequest requestGetFromPath:@"/bar/B"];
    self.generatorA = [[FakeRequestGenerator alloc] init];
    self.generatorB = [[FakeRequestGenerator alloc] init];
}

- (void)tearDown
{
    self.requestA = nil;
    self.requestB = nil;
    self.generatorA = nil;
    self.generatorB = nil;
    [super tearDown];
}

- (void)testThatItReturnsARequest;
{
    // given
    self.generatorA.nextRequest = self.requestA;
    NSArray *sut = @[self.generatorA];
    
    // when
    ZMTransportRequest *request = [sut nextRequest];
    
    // then
    XCTAssertNotNil(request);
    XCTAssertTrue([request isKindOfClass:ZMTransportRequest.class]);
    XCTAssertEqual(request, self.requestA);
}

- (void)testThatItReturnsTheFirstRequest;
{
    // given
    self.generatorA.nextRequest = nil;
    self.generatorB.nextRequest = self.requestB;
    NSArray *sut = @[self.generatorA, self.generatorB];
    
    // when
    ZMTransportRequest *request = [sut nextRequest];
    
    // then
    XCTAssertNotNil(request);
    XCTAssertTrue([request isKindOfClass:ZMTransportRequest.class]);
    XCTAssertEqual(request, self.requestB);
}

@end
