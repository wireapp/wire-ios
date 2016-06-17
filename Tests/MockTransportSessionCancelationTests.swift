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


import ZMCMockTransport
import ZMTransport
import XCTest

class MockTransportSessionCancellationTests : MockTransportSessionTests {
    
    func testThatItCallsTheTaskCreationCallback() {
        
        // given
        let request = ZMTransportRequest(getFromPath: "Foo")
        var identifier : ZMTaskIdentifier?
        request.addTaskCreatedHandler(ZMTaskCreatedHandler(onGroupQueue: self.fakeSyncContext) {
            identifier = $0
        })
        
        // when
        sut.mockedTransportSession().attemptToEnqueueSyncRequestWithGenerator { () -> ZMTransportRequest! in
            return request
        }
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertNotNil(identifier)
    }
    
    func testThatItCanCancelARequestThatIsNotCompletedYet() {
        
        // given
        let request = ZMTransportRequest(getFromPath: "Foo")
        var requestCompleted = false
        var identifier : ZMTaskIdentifier?

        request.addCompletionHandler(ZMCompletionHandler(onGroupQueue: self.fakeSyncContext) { response in
            XCTAssertEqual(response.HTTPStatus, 0)
            XCTAssertTrue(response.transportSessionError.isTryAgainLaterError)
            requestCompleted = true
            })
        request.addTaskCreatedHandler(ZMTaskCreatedHandler(onGroupQueue: self.fakeSyncContext) {
            identifier = $0
            })
        
        sut.responseGeneratorBlock = { (_ : ZMTransportRequest!) -> ZMTransportResponse! in
            return ResponseGenerator.ResponseNotCompleted
        }
        
        // when
        sut.mockedTransportSession().attemptToEnqueueSyncRequestWithGenerator { () -> ZMTransportRequest! in
            return request
        }
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertFalse(requestCompleted)
        XCTAssertNotNil(identifier)
        
        // when
        sut.mockedTransportSession().cancelTaskWithIdentifier(identifier)
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))

        // then
        XCTAssertTrue(requestCompleted)
    }
    
    func testThatItDoesNotCancelARequestThatIsAlreadyCompleted() {
        
        // given
        let request = ZMTransportRequest(getFromPath: "Foo")
        var requestCompletedCount = 0
        var identifier : ZMTaskIdentifier?
        
        request.addCompletionHandler(ZMCompletionHandler(onGroupQueue: self.fakeSyncContext) { response in
            XCTAssertEqual(requestCompletedCount, 0)
            XCTAssertEqual(response.HTTPStatus, 404)
            requestCompletedCount += 1
            })
        request.addTaskCreatedHandler(ZMTaskCreatedHandler(onGroupQueue: self.fakeSyncContext) {
            identifier = $0
            })
        
        // when
        sut.mockedTransportSession().attemptToEnqueueSyncRequestWithGenerator { () -> ZMTransportRequest! in
            return request
        }
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertEqual(requestCompletedCount, 1)
        XCTAssertNotNil(identifier)
        
        // when
        sut.mockedTransportSession().cancelTaskWithIdentifier(identifier)
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertEqual(requestCompletedCount, 1)
    }
    
}