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


#import "MessagingTest.h"
#import "ZMApplicationLaunchStatus.h"

@interface ZMApplicationLaunchStatusTests : MessagingTest
@property (nonatomic) ZMApplicationLaunchStatus *sut;
@property (nonatomic) id mockApplication;
@end

@implementation ZMApplicationLaunchStatusTests

- (void)setUp {
    [super setUp];
    self.mockApplication = [OCMockObject niceMockForClass:[ZMApplication class]];
    self.sut = [[ZMApplicationLaunchStatus alloc] initWithManagedObjectContext:self.uiMOC];
}

- (void)tearDown {
    self.mockApplication = nil;
    self.sut = nil;
    [super tearDown];
}

- (void)testThatItReturnsForegroundPerDefault
{
    // when
    ZMApplicationLaunchState state = [self.sut currentState];
    
    // then
    XCTAssertEqual(state, ZMApplicationLaunchStateForeground);
}

- (void)testThatItReturnsBackgroundWhenTheApplicationWasLaunchedInTheBackground
{
    // given
    [[[self.mockApplication expect] andReturnValue:OCMOCK_VALUE(UIApplicationStateBackground)] applicationState];
    
    // when
    [self.sut application:self.mockApplication didFinishLaunchingWithOptions:nil];
    ZMApplicationLaunchState state = [self.sut currentState];
    
    // then
    XCTAssertEqual(state, ZMApplicationLaunchStateBackground);
    [self.mockApplication verify];
}

- (void)testThatItResetsBackgroundFetchStateAfter_FetchEnded
{
    // given
    [self.sut startedBackgroundFetch];
    WaitForAllGroupsToBeEmpty(0.5);

    // when
    ZMApplicationLaunchState state1 = [self.sut currentState];
    
    // then
    XCTAssertEqual(state1, ZMApplicationLaunchStateBackgroundFetch);
    
    // and when
    [self.sut finishedBackgroundFetch];
    WaitForAllGroupsToBeEmpty(0.5);

    ZMApplicationLaunchState state2 = [self.sut currentState];
    
    //then
    XCTAssertEqual(state2, ZMApplicationLaunchStateForeground);
}


- (void)testThatItResetsBackgroundFetchStateAfter_EnterforeGround
{
    // given
    [self.sut startedBackgroundFetch];
    WaitForAllGroupsToBeEmpty(0.5);

    // when
    ZMApplicationLaunchState state1 = [self.sut currentState];
    
    // then
    XCTAssertEqual(state1, ZMApplicationLaunchStateBackgroundFetch);
    
    // and when
    [self.sut appWillEnterForeground];
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMApplicationLaunchState state2 = [self.sut currentState];
    
    //then
    XCTAssertEqual(state2, ZMApplicationLaunchStateForeground);
}


- (void)testThatItResetsBackgroundStateAfter_EnterforeGround
{
    // given
    [[[self.mockApplication expect] andReturnValue:OCMOCK_VALUE(UIApplicationStateBackground)] applicationState];
    [self.sut application:self.mockApplication didFinishLaunchingWithOptions:nil];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    ZMApplicationLaunchState state1 = [self.sut currentState];
    
    // then
    XCTAssertEqual(state1, ZMApplicationLaunchStateBackground);
    
    // and when
    [self.sut appWillEnterForeground];
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMApplicationLaunchState state2 = [self.sut currentState];
    
    //then
    XCTAssertEqual(state2, ZMApplicationLaunchStateForeground);
}

@end
