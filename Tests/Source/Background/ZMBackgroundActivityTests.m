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
@import ZMTesting;
@import OCMock;

#import "ZMBackgroundActivity.h"

@interface ZMBackgroundActivityTests : ZMTBaseTest


@end

@implementation ZMBackgroundActivityTests

- (void)setUp;
{
    [super setUp];
}

- (void)tearDown;
{
    [super tearDown];
}

- (void)testThatBackgroundActivityEndItsActivityInTheGivenGroupQueue;
{
    // given
    id mockGroupQueue = [OCMockObject mockForProtocol:@protocol(ZMSGroupQueue)];
    
    id mockApplication = [OCMockObject niceMockForClass:UIApplication.class];
    [[[[mockApplication stub] andReturn:mockApplication] classMethod] sharedApplication];
    
    ZMBackgroundActivity *activity = [ZMBackgroundActivity beginBackgroundActivityWithName:@"JCVD" groupQueue:mockGroupQueue application:[UIApplication sharedApplication]];
    
    // expect
    [[mockGroupQueue expect] performGroupedBlock:OCMOCK_ANY];
    
    //when
    [activity endActivity];
    
    //then
    [mockGroupQueue verify];
    
    [mockGroupQueue stopMocking];
    [mockApplication stopMocking];
}

@end
