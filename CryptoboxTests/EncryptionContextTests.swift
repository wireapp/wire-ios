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


import XCTest
import Cryptobox

class EncryptionContextTests: XCTestCase {

    /// This test verifies that the critical section (in usingSessions)
    /// can not be entered at the same time on two different EncryptionContext
    func testThatItBlockWhileUsingSessionsOnTwoDifferentObjects() {
        
        // GIVEN
        let tempDir = createTempFolder()
        
        // have to do work on other queues because the main thread can't be blocked
        let queue1 = dispatch_queue_create(self.name!, DISPATCH_QUEUE_SERIAL)
        let queue2 = dispatch_queue_create(self.name!, DISPATCH_QUEUE_SERIAL)
        
        // coordinate between the two threads to make sure that they are executed in the right order
        let context2CanEnterSemaphore = dispatch_semaphore_create(0)
        let context1CanCompleteSemaphore = dispatch_semaphore_create(0)
        let queue2IsDoneSemaphore = dispatch_semaphore_create(0)
        
        // whether the queues entered the critical section
        var queue1EnteredCriticalSection = false
        var queue1LeftCriticalSection = false
        var queue2EnteredCriticalSection = false
        var queue2LeftCriticalSection = false
        
        // WHEN
        
        // queue 1 will enter critical section and wait there until told to complete
        dispatch_async(queue1) {

            // entering the critical section
            EncryptionContext(path: tempDir).perform { _ in
                queue1EnteredCriticalSection = true
                // signal queue2 other thread that it should attempt to enter critical section
                dispatch_semaphore_signal(context2CanEnterSemaphore)
                // wait until it's told to leave critical section
                dispatch_semaphore_wait(context1CanCompleteSemaphore, DISPATCH_TIME_FOREVER)
            }
            queue1LeftCriticalSection = true
        }
        
        // queue 2 will try to enter critical section, but should block (because of queue 1)
        dispatch_async(queue2) {
            
            // make sure queue 1 is in the right place (critical section) before attempting to enter critical section
            dispatch_semaphore_wait(context2CanEnterSemaphore, DISPATCH_TIME_FOREVER)
            EncryptionContext(path: tempDir).perform { _ in
                // will not get here until queue1 has quit critical section
                queue2EnteredCriticalSection = true
            }
            queue2LeftCriticalSection = true
            dispatch_semaphore_signal(queue2IsDoneSemaphore)
        }
        
        // wait a few ms so that all threads are ready
        NSThread.sleepForTimeInterval(0.3)
        
        // THEN
        XCTAssertTrue(queue1EnteredCriticalSection)
        XCTAssertFalse(queue1LeftCriticalSection)
        XCTAssertFalse(queue2EnteredCriticalSection)
        XCTAssertFalse(queue2LeftCriticalSection)
        
        // WHEN
        dispatch_semaphore_signal(context1CanCompleteSemaphore)
        
        // THEN
        dispatch_semaphore_wait(queue2IsDoneSemaphore, DISPATCH_TIME_FOREVER)
        XCTAssertTrue(queue1EnteredCriticalSection)
        XCTAssertTrue(queue1LeftCriticalSection)
        XCTAssertTrue(queue2EnteredCriticalSection)
        XCTAssertTrue(queue2LeftCriticalSection)
    }

    func testThatItDoesNotBlockWhileUsingSessionsMultipleTimesOnTheSameObject() {
        
        // GIVEN
        let tempDir = createTempFolder()
        
        let mainContext = EncryptionContext(path: tempDir)
        let invocation1 = self.expectationWithDescription("first begin using session")
        let invocation2 = self.expectationWithDescription("second begin using session")

        
        // WHEN
        // enter critical section
        mainContext.perform { _ in
            invocation1.fulfill()
            
            // enter again
            mainContext.perform { _ in
                invocation2.fulfill()
            }
        }
        
        // THEN
        self.waitForExpectationsWithTimeout(0) { _ in }

    }
    
    func testThatItReceivesTheSameSessionStatusWithNestedPerform() {
        
        // GIVEN
        let tempDir = createTempFolder()
        
        let mainContext = EncryptionContext(path: tempDir)
        var lastStatus : EncryptionSessionsDirectory? = nil
 
        let invocation1 = self.expectationWithDescription("first begin using session")
        let invocation2 = self.expectationWithDescription("second begin using session")
        
        // WHEN
        
        // enter critical section
        mainContext.perform { context1 in
            lastStatus = context1
            invocation1.fulfill()
        
            mainContext.perform { context2 in
                XCTAssertTrue(lastStatus === context2)
                invocation2.fulfill()
            }
        }
        
        // THEN
        self.waitForExpectationsWithTimeout(0) { _ in }
    }
    
    func testThatItSafelyEncryptDecryptDuringNestedPerform() {
        
        // GIVEN
        let tempDir = createTempFolder()
        
        let mainContext = EncryptionContext(path: tempDir)
        
        let someTextToEncrypt = "ENCRYPT THIS!"
        
        // WHEN
        
        // enter critical section
        mainContext.perform { context1 in
            
            try! context1.createClientSession(hardcodedClientId, base64PreKeyString: hardcodedPrekey)
            
            mainContext.perform { context2 in
                try! context2.encrypt(someTextToEncrypt.dataUsingEncoding(NSUTF8StringEncoding)!, recipientClientId: hardcodedClientId)
                
            }
            
            try! context1.encrypt(someTextToEncrypt.dataUsingEncoding(NSUTF8StringEncoding)!, recipientClientId: hardcodedClientId)
        }
        
        // THEN 
        // it didn't crash
    }

    
    func testThatItDoesNotReceivesTheSameSessionStatusIfDonePerforming() {
        
        // GIVEN
        let tempDir = createTempFolder()
        
        let mainContext = EncryptionContext(path: tempDir)
        var lastStatus : EncryptionSessionsDirectory? = nil
        
        let invocation1 = self.expectationWithDescription("first begin using session")
        let invocation2 = self.expectationWithDescription("second begin using session")
        
        // WHEN
        
        // enter critical section
        mainContext.perform { context in
            lastStatus = context
            invocation1.fulfill()
        }
        
        // THEN
        // enter again
        mainContext.perform { context in
            invocation2.fulfill()
            XCTAssertFalse(lastStatus === context)
        }
        
        self.waitForExpectationsWithTimeout(0) { _ in }
    }
}
