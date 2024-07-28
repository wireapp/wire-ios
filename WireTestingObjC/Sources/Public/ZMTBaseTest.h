//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

#import <XCTest/XCTest.h>
#import <WireSystemObjC/WireSystemObjC.h>
#import <WireTestingObjC/ZMTFailureRecorder.h>

@class ZMSDispatchGroup;
@protocol ZMSGroupQueue;

extern void PrintTimeoutWarning(XCTestCase *_Nonnull test, NSTimeInterval const maxTimeout, NSTimeInterval const actualTimeout);

typedef BOOL(^VerificationBlock)(void);


@interface ZMTBaseTest : XCTestCase

/// Calls @c -verify during @c -tearDown
- (void)verifyMockLater:(nonnull id)mock;
/// Verify all mocks
- (void)verifyMocksNow;

- (void)setUp;
- (void)tearDown;

/// Should be wrapped in call to @c XCTAssert()
- (BOOL)waitOnMainLoopUntilBlock:(nonnull VerificationBlock)block timeout:(NSTimeInterval)timeout ZM_MUST_USE_RETURN NS_SWIFT_UNAVAILABLE("This is considered legacy code and should not be used.");

/// Wait for a condition to be met, periodically verifying if the condition is met. It will verify at least once
- (BOOL)waitWithTimeout:(NSTimeInterval)timeout verificationBlock:(nonnull VerificationBlock)block ZM_MUST_USE_RETURN NS_SWIFT_UNAVAILABLE("This is considered legacy code and should not be used.");
/// Wait for a condition to be met, periodically verifying if the condition is met. It will verify at least once
- (BOOL)waitUntilDate:(nonnull NSDate *)runUntil verificationBlock:(nonnull VerificationBlock)block ZM_MUST_USE_RETURN NS_SWIFT_UNAVAILABLE("This is considered legacy code and should not be used.");

/// Returns whether we are debugging the tests. This is enabled by setting the "DEBUG_TESTS" environment variable to 1
+ (BOOL)isDebuggingTests;

/// timer calculation - will be adjusted to device speed and whether we are debugging tests
+ (NSTimeInterval)timeToUseForOriginalTime:(NSTimeInterval)originalTime;
/// spins the run loop for a reasonable time
+ (void)performRunLoopTick NS_SWIFT_UNAVAILABLE("This is considered legacy code and should not be used.");

/// If this is set to true, we will ignore the debug flag for tests in timer (use this to test timer test failures)
@property (nonatomic) BOOL ignoreTestDebugFlagForTestTimers;

/// The test dispatch group
@property (nonatomic, readonly, nonnull) ZMSDispatchGroup *dispatchGroup;
/// List of dispatch groups that are waited on when calling @c waitForAllGroupsToBeEmptyWithTimeout
@property (nonatomic, readonly, nonnull) NSArray<ZMSDispatchGroup *> *allDispatchGroups;


/// Spins the main queue run loop for the given amount of time
- (void)spinMainQueueWithTimeout:(NSTimeInterval)timeout;

/// Wait for all dispatch groups to be empty
- (BOOL)waitForAllGroupsToBeEmptyWithTimeout:(NSTimeInterval)timeout ZM_MUST_USE_RETURN NS_SWIFT_UNAVAILABLE_FROM_ASYNC("Don't use wait in async contexts!");

- (XCTestExpectation *_Nonnull)customExpectationWithDescription:(NSString *_Nonnull)description NS_SWIFT_NAME(customExpectation(description:));

- (XCTestExpectation *_Nonnull)customExpectationForNotification:(NSNotificationName _Nonnull)notificationName object:(id _Nullable)objectToObserve handler:(XCNotificationExpectationHandler _Nullable)handlerOrNil;

- (XCTestExpectation *_Nonnull)customKeyValueObservingExpectationForObject:(id _Nonnull)objectToObserve keyPath:(NSString *_Nonnull)keyPath expectedValue:(id  _Nullable)expectedValue;

- (BOOL)waitForCustomExpectationsWithTimeout:(NSTimeInterval)timeout handler:(nullable XCWaitCompletionHandler)handlerOrNil ZM_MUST_USE_RETURN NS_SWIFT_UNAVAILABLE_FROM_ASYNC("Don't use wait in async contexts!");
- (BOOL)waitForCustomExpectationsWithTimeout:(NSTimeInterval)timeout ZM_MUST_USE_RETURN NS_SWIFT_UNAVAILABLE_FROM_ASYNC("Don't use wait in async contexts!");

/// perform operations while not considering ZMLogErrors as test failure
- (void)performIgnoringZMLogError:(nonnull void(^)(void))block;
/// Disable test failure on ZMLogErrors temporary, use this for Swift async function. Turn on back after. 
/// If possible prefer `performIgnoringZMLogError`
- (void)disableZMLogError:(BOOL)disabled;

/// Returns the data of a small JPEG image
- (nonnull NSData *)verySmallJPEGData;
/// Returns the data of a small JPEG image
+ (nonnull NSData *)verySmallJPEGData;
/// Returns the data of a medium JPEG image
- (nonnull NSData *)mediumJPEGData;
/// Returns the data of a medium JPEG image
+ (nonnull NSData *)mediumJPEGData;
/// Returns the data of a large JPEG image
- (nonnull NSData *)largeJPEGData;
/// Returns the data of a large JPEG image
+ (nonnull NSData *)largeJPEGData;

@property (nonatomic, strong, nonnull, readonly) id<ZMSGroupQueue> fakeUIContext;
@property (nonatomic, strong, nonnull, readonly) id<ZMSGroupQueue> fakeSyncContext;

@property (nonatomic, null_unspecified) NSUserDefaults *sharedUserDefaults;


@end

@interface ZMTBaseTest (Asserts)

- (void)assertDictionary:(nonnull NSDictionary *)d1 isEqualToDictionary:(nonnull NSDictionary *)d2 name1:(nonnull char const *)name1 name2:(nonnull char const *)name2 failureRecorder:(nullable ZMTFailureRecorder *)failureRecorder;
- (void)assertDictionary:(nonnull NSDictionary *)d1 isEqualToDictionary:(nonnull NSDictionary *)d2 name1:(nonnull char const *)name1 name2:(nonnull char const *)name2 ignoreKeys:(nonnull NSArray *)ignoredKeys failureRecorder:(nullable ZMTFailureRecorder *)failureRecorder;

- (void)assertArray:(nonnull NSArray *)a1 hasSameElementsAsArray:(nonnull NSArray *)a2 name1:(nonnull char const *)name1 name2:(nonnull char const *)name2 failureRecorder:(nullable ZMTFailureRecorder *)failureRecorder;

@end
