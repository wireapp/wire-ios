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

#import "SoundEventRulesWatchDog.h"



static NSTimeInterval const IgnoreTime = 1 * 60;



@interface SoundEventRulesWatchDogTests : XCTestCase

@property (nonatomic, strong) SoundEventRulesWatchDog *watchDog;

@end

@implementation SoundEventRulesWatchDogTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    self.watchDog = [[SoundEventRulesWatchDog alloc] initWithIgnoreTime:IgnoreTime];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    self.watchDog = nil;
}

- (void)testThatWatchDogStaysMuted
{
    // given
    // when
    self.watchDog.muted = YES;
    
    // then
    XCTAssertFalse(self.watchDog.outputAllowed);
}

- (void)testThatWatchDogAllowesOutputForAfterPassedIgnoreTime
{
    // given
    // when
    self.watchDog.muted = NO;
    self.watchDog.startIgnoreDate = [NSDate dateWithTimeIntervalSinceNow:-2 * IgnoreTime];
    
    // then
    XCTAssertTrue(self.watchDog.outputAllowed);
}

- (void)testThatWatchDogDisallowesOutputForNotYetPassedIgnoreTime
{
    // given
    // when
    self.watchDog.muted = NO;
    self.watchDog.startIgnoreDate = [NSDate date];
    
    // then
    XCTAssertFalse(self.watchDog.outputAllowed);
}

@end
