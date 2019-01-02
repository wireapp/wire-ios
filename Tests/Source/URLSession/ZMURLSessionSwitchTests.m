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
@import WireSystem;
@import WireUtilities;

#import "ZMURLSessionSwitch.h"
#import "ZMURLSession.h"
#import "ZMSessionCancelTimer.h"



@interface FakeSessionCancelTimer : NSObject

- (instancetype)initWithURLSession:(ZMURLSession *)session timeout:(NSTimeInterval)timeout;

- (void)start;

@property (nonatomic) ZMURLSession *session;
@property (nonatomic) NSTimeInterval timeout;
@property (nonatomic) int startCounter;
@property (nonatomic) int cancelCounter;

@end



static NSHashTable *sessionCancelTimers;



@implementation FakeSessionCancelTimer

- (instancetype)initWithURLSession:(ZMURLSession *)session timeout:(NSTimeInterval)timeout;
{
    self = [super init];
    if (self) {
        self.session = session;
        self.timeout = timeout;
    }
    [sessionCancelTimers addObject:self];
    return self;
}

- (void)start;
{
    ++self.startCounter;
}

- (void)cancel;
{
    ++self.cancelCounter;
}

@end

//
//
#pragma mark - Tests
//
//


@interface ZMURLSessionSwitchTests : XCTestCase

@property (nonatomic) ZMURLSessionSwitch *sut;
@property (nonatomic) ZMURLSession *foregroundSession;
@property (nonatomic) ZMURLSession *backgroundSession;
@property (nonatomic) ZMURLSession *voipSession;

@end



@implementation ZMURLSessionSwitchTests

- (void)setUp
{
    [super setUp];
    sessionCancelTimers = [NSHashTable weakObjectsHashTable];
    
    NSOperationQueue *q = [NSOperationQueue zm_serialQueueWithName:self.name];
    ZMURLSession *sessionA = [[ZMURLSession alloc] initWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:(id) self delegateQueue:q identifier:@"session-a"];
    ZMURLSession *sessionB = [[ZMURLSession alloc] initWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:(id) self delegateQueue:q identifier:@"session-b"];
    ZMURLSession *sessionC = [[ZMURLSession alloc] initWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:(id) self delegateQueue:q identifier: @"session-c"];

    self.foregroundSession = sessionA;
    self.backgroundSession = sessionB;
    self.voipSession = sessionC;

    self.sut = [[ZMURLSessionSwitch alloc] initWithForegroundSession:self.foregroundSession
                                                   backgroundSession:self.backgroundSession
                                                      voipSession:self.voipSession
                                             sessionCancelTimerClass:FakeSessionCancelTimer.class];
}

- (void)tearDown
{
    sessionCancelTimers = nil;
    [self.sut tearDown];
    self.sut = nil;
    [super tearDown];
}

- (void)testThatItUsesTheForegroundSessionByDefault;
{
    XCTAssertEqual(self.sut.currentSession, self.foregroundSession);
}

- (void)testThatItSwitchesToTheBackgroundSession;
{
    // when
    [self.sut switchToBackgroundSession];
    
    XCTAssertEqual(self.sut.currentSession, self.backgroundSession);
}

- (void)testThatItSwitchesBackToTheForegroundSession;
{
    // when
    [self.sut switchToBackgroundSession];
    [self.sut switchToForegroundSession];
    
    XCTAssertEqual(self.sut.currentSession, self.foregroundSession);
}

- (void)testThatItCancelsTheCancellationTimerWhenSwitchingBackToTheForegroundSession;
{
    // when
    [self.sut switchToBackgroundSession];
    FakeSessionCancelTimer *timer = sessionCancelTimers.anyObject;
    [self.sut switchToForegroundSession];
    
    XCTAssertEqual(timer.cancelCounter, 1);
}

- (void)testThatItReturnsAllSessions;
{
    // when
    NSArray *allSessions = self.sut.allSessions;
    NSArray *expectedSessions = @[self.sut.foregroundSession, self.sut.backgroundSession, self.voipSession];
    
    // then
    XCTAssertEqualObjects(allSessions, expectedSessions);
}

- (void)testThatItCreatesASessionCancelTimerWhenSwitchingToTheBackgroundSession;
{
    // when
    [self.sut switchToBackgroundSession];
    
    // then
    NSArray *timers = sessionCancelTimers.allObjects;
    XCTAssertEqual(timers.count, 2u);
    NSArray <ZMURLSession *>*sessions = [timers mapWithBlock:^id(FakeSessionCancelTimer *obj) {
        return obj.session;
    }];
    XCTAssertTrue([sessions containsObject: self.voipSession]);
    XCTAssertTrue([sessions containsObject: self.foregroundSession]);

    XCTAssertEqual([timers.firstObject timeout], ZMSessionCancelTimerDefaultTimeout);
    XCTAssertEqual([timers.firstObject startCounter], 1);
    
    XCTAssertEqual([timers.lastObject timeout], ZMSessionCancelTimerDefaultTimeout);
    XCTAssertEqual([timers.lastObject startCounter], 1);
}

- (void)testThatItDoesNotCreateASessionCancelTimerWhenSwitchingBackToTheForegroundSession;
{
    // when
    [self.sut switchToBackgroundSession];
    [sessionCancelTimers removeAllObjects];
    [self.sut switchToForegroundSession];
    
    // then
    NSArray *timers = sessionCancelTimers.allObjects;
    XCTAssertEqual(timers.count, 0u);
}

- (void)testThatItDoesNotCreateASessionCancelTimerWhenNotSwitching_1
{
    // when
    [self.sut switchToForegroundSession];
    
    // then
    XCTAssertEqual(sessionCancelTimers.count, 0u);
}

- (void)testThatItDoesNotCreateASessionCancelTimerWhenNotSwitching_2
{
    // when
    [self.sut switchToBackgroundSession];
    [sessionCancelTimers removeAllObjects];
    [self.sut switchToBackgroundSession];
    
    // then
    XCTAssertEqual(sessionCancelTimers.count, 0u);
}




@end
