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

import XCTest

@testable import WireSystem

final class GroupQueueTests: XCTestCase {

    func testThatItNotifiesWhenEnteringAndLeavingAGroupOnce() {
        // TODO: implement

        /*

         // given
         __block BOOL notified = NO; // I can't use XCTestExpectation because I have no way to verify that is has
                                     // not been fulfilled yet without making the test fail
         ZMSDispatchGroup *sut = [ZMSDispatchGroup groupWithLabel:@"test group"];
         dispatch_queue_t queue = dispatch_queue_create("test queue", DISPATCH_QUEUE_SERIAL);
         [sut enter];

         // when
         [sut notifyOnQueue:queue block:^{
             notified = YES;
         }];

         // then
         dispatch_sync(queue, ^{ // this is here to make sure there are no previous op running on the queue
             XCTAssertFalse(notified);
         });

         // and when
         [sut leave];

         // then
         dispatch_sync(queue, ^{ // this is here to make sure there are no previous op running on the queue
             XCTAssertTrue(notified);
         });

         */
    }

    func testThatItNotifiesWhenEnteringAndLeavingAGroupThatWasInjected() {
        // TODO: implement

        /*

         // given
         __block BOOL notified = NO; // I can't use XCTestExpectation because I have no way to verify that is has
         // not been fulfilled yet without making the test fail
         dispatch_group_t rawGroup = dispatch_group_create();
         ZMSDispatchGroup *sut = [ZMSDispatchGroup groupWithDispatchGroup:rawGroup label:@"Test"];
         dispatch_queue_t queue = dispatch_queue_create("test queue", DISPATCH_QUEUE_SERIAL);
         dispatch_group_enter(rawGroup);

         // when
         [sut notifyOnQueue:queue block:^{
             notified = YES;
         }];

         // then
         dispatch_sync(queue, ^{ // this is here to make sure there are no previous op running on the queue
             XCTAssertFalse(notified);
         });

         // and when
         [sut leave];

         // then
         dispatch_sync(queue, ^{ // this is here to make sure there are no previous op running on the queue
             XCTAssertTrue(notified);
         });

         */
    }

    func testThatItNotifiesImmediatelyIfTheGroupWasNotEntered() {
        // TODO: implement

        /*

         // given
         __block BOOL notified = NO; // I can't use XCTestExpectation because I have no way to verify that is has
         // not been fulfilled yet without making the test fail
         ZMSDispatchGroup *sut = [ZMSDispatchGroup groupWithLabel:@"test group"];
         dispatch_queue_t queue = dispatch_queue_create("test queue", DISPATCH_QUEUE_SERIAL);

         // when
         [sut notifyOnQueue:queue block:^{
             notified = YES;
         }];

         // then
         dispatch_sync(queue, ^{ // this is here to make sure there are no previous op running on the queue
             XCTAssertTrue(notified);
         });

         */
    }

    func testThatItNotifiesWhenEnteringAndLeavingAGroupMultipleTimes() {
        // TODO: implement

        /*

         // given
         __block BOOL notified = NO; // I can't use XCTestExpectation because I have no way to verify that is has
                                     // not been fulfilled yet without making the test fail
         ZMSDispatchGroup *sut = [ZMSDispatchGroup groupWithLabel:@"test group"];
         dispatch_queue_t queue = dispatch_queue_create("test queue", DISPATCH_QUEUE_SERIAL);
         [sut enter]; // enterinc once
         [sut enter]; // entering twice

         // when
         [sut notifyOnQueue:queue block:^{
             notified = YES;
         }];
         [sut leave]; // leave once

         // then
         dispatch_sync(queue, ^{ // this is here to make sure there are no previous op running on the queue

             XCTAssertFalse(notified);
         });

         // and when
         [sut leave]; // leaving twice

         // then
         dispatch_sync(queue, ^{ // this is here to make sure there are no previous op running on the queue
             XCTAssertTrue(notified);
         });

         */
    }

    func testThatItNotifiesOnTheRightQueueAfterEnteringAndLeaving() {
        // TODO: implement

        /*

         // given
         __block BOOL notified = NO; // I can't use XCTestExpectation because I have no way to verify that is has
                                     // not been fulfilled yet without making the test fail
         ZMSDispatchGroup *sut = [ZMSDispatchGroup groupWithLabel:@"test group"];
         [sut enter];

         dispatch_queue_t queue = dispatch_queue_create("test queue", DISPATCH_QUEUE_SERIAL);

         dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
         dispatch_async(queue, ^{
             dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);  // this will block this queue until we signal
                                                                         // preventing the notify to be executed
                                                                         // only if it's enqueued on this queue
         });

         // when
         [sut notifyOnQueue:queue block:^{
             notified = YES;
         }];
         [sut leave];
         [NSThread sleepForTimeInterval:0.1f];

         // then
         XCTAssertFalse(notified);

         // and when
         dispatch_semaphore_signal(semaphore);

         // then
         dispatch_sync(queue, ^{ // this is here to make sure there are no previous op running on the queue
             XCTAssertTrue(notified);
         });

         */
    }

    func testThatItNotifiesWhenPerformingAsync() {
        // TODO: implement

        /*

         // given
         __block BOOL notified = NO; // I can't use XCTestExpectation because I have no way to verify that is has
         // not been fulfilled yet without making the test fail
         ZMSDispatchGroup *sut = [ZMSDispatchGroup groupWithLabel:@"test group"];

         dispatch_queue_t queue = dispatch_queue_create("test queue", DISPATCH_QUEUE_SERIAL);
         dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
         [sut asyncOnQueue:queue block:^{
             dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
         }];

         // when
         [sut notifyOnQueue:queue block:^{
             notified = YES;
         }];
         [NSThread sleepForTimeInterval:0.1f];

         // then
         XCTAssertFalse(notified);

         // and when
         dispatch_semaphore_signal(semaphore);
         [NSThread sleepForTimeInterval:0.1];

         // then
         dispatch_sync(queue, ^{ // this is here to make sure there are no previous op running on the queue
             XCTAssertTrue(notified);
         });

         */
    }

    func testThatItWaitsAfterEnteringWithATimeoutThatExpires() {
        // TODO: implement

        /*

         // given
         ZMSDispatchGroup *sut = [ZMSDispatchGroup groupWithLabel:@"test group"];
         [sut enter];

         // when
         long result = [sut waitWithTimeout:dispatch_time(DISPATCH_TIME_NOW, 200LL * NSEC_PER_MSEC)];

         // then
         XCTAssertNotEqual(result, 0);
         [sut leave];

         */
    }

    func testThatItWaitsAfterEnteringWithATimeoutThatDoesNotExpire() {
        // TODO: implement

        /*

         // given
         ZMSDispatchGroup *sut = [ZMSDispatchGroup groupWithLabel:@"test group"];
         [sut enter];

         dispatch_queue_t queue = dispatch_queue_create("test", DISPATCH_QUEUE_CONCURRENT);
         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500LL * NSEC_PER_MSEC), queue, ^{
             [sut leave];
         });

         // when
         long result = [sut waitWithTimeout:DISPATCH_TIME_FOREVER];

         // then
         XCTAssertEqual(result, 0);

         */
    }
}
