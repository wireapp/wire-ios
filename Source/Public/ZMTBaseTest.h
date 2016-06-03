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


#import <XCTest/XCTest.h>
#import <ZMCSystem/ZMCSystem.h>
#import "ZMTFailureRecorder.h"


extern void PrintTimeoutWarning(XCTestCase *test, NSTimeInterval const maxTimeout, NSTimeInterval const actualTimeout);

typedef BOOL(^VerificationBlock)(void);


@interface ZMTBaseTest : XCTestCase

/// Calls @c -verify during @c -tearDown
- (void)verifyMockLater:(id)mock;
- (void)verifyMocksNow;

- (void)setUp ZM_REQUIRES_SUPER;
- (void)tearDown ZM_REQUIRES_SUPER;

/// Should be wrapped in call to @c XCTAssert()
- (BOOL)waitOnMainLoopUntilBlock:(VerificationBlock)block timeout:(NSTimeInterval)timeout ZM_MUST_USE_RETURN;

- (BOOL)waitWithTimeout:(NSTimeInterval)timeout verificationBlock:(VerificationBlock)block ZM_MUST_USE_RETURN;
- (BOOL)waitUntilDate:(NSDate *)runUntil verificationBlock:(VerificationBlock)block ZM_MUST_USE_RETURN;

/// Returns whether we are debugging the tests. This is enabled by setting the "DEBUG_TESTS" environment variable to 1
+ (BOOL)isDebuggingTests;

/// timer calculation - will be adjusted to device speed and whether we are debugging tests
+ (NSTimeInterval)timeToUseForOriginalTime:(NSTimeInterval)originalTime;
/// spins the run loop for a reasonable time
+ (void)performRunLoopTick;

/// If this is set to true, we will ignore the debug flag for tests in timer (use this to test timer test failures)
@property (nonatomic) BOOL ignoreTestDebugFlagForTestTimers;
@property (nonatomic, readonly) ZMSDispatchGroup *dispatchGroup;

- (void)spinMainQueueWithTimeout:(NSTimeInterval)timeout;
- (BOOL)waitForAllGroupsToBeEmptyWithTimeout:(NSTimeInterval)timeout ZM_MUST_USE_RETURN;

- (BOOL)waitForCustomExpectationsWithTimeout:(NSTimeInterval)timeout handler:(XCWaitCompletionHandler)handlerOrNil ZM_MUST_USE_RETURN;
- (BOOL)waitForCustomExpectationsWithTimeout:(NSTimeInterval)timeout ZM_MUST_USE_RETURN;
- (BOOL)verifyAllExpectationsNow ZM_MUST_USE_RETURN;

/// perform operations while not considering ZMLogErrors as test failure
- (void)performIgnoringZMLogError:(void(^)(void))block;

/// Returns the data of a small JPEG image
- (NSData *)verySmallJPEGData;
/// Returns the data of a small JPEG image
+ (NSData *)verySmallJPEGData;
/// Returns the data of a medium JPEG image
- (NSData *)mediumJPEGData;
/// Returns the data of a medium JPEG image
+ (NSData *)mediumJPEGData;

@property (nonatomic, strong) id<ZMSGroupQueue> fakeUIContext;
@property (nonatomic, strong) id<ZMSGroupQueue> fakeSyncContext;

@end


@interface ZMTBaseTest (Asserts)

- (void)assertDictionary:(NSDictionary *)d1 isEqualToDictionary:(NSDictionary *)d2 name1:(char const *)name1 name2:(char const *)name2 failureRecorder:(ZMTFailureRecorder *)failureRecorder;
- (void)assertDictionary:(NSDictionary *)d1 isEqualToDictionary:(NSDictionary *)d2 name1:(char const *)name1 name2:(char const *)name2 ignoreKeys:(NSArray *)ignoredKeys failureRecorder:(ZMTFailureRecorder *)failureRecorder;

- (void)assertArray:(NSArray *)a1 hasSameElementsAsArray:(NSArray *)a2 name1:(char const *)name1 name2:(char const *)name2 failureRecorder:(ZMTFailureRecorder *)failureRecorder;

@end

